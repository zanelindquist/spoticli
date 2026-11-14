#!/bin/bash

USER_ID=$1
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"
source "$PROJECT_ROOT/lib/images.sh"
source "$PROJECT_ROOT/lib/components.sh"
source "$PROJECT_ROOT/lib/input.sh"
source "$PROJECT_ROOT/ui/topbar.sh"

# Load up the user's temporary directory
user_temp_dir="$PROJECT_ROOT/data/users/$USER_ID/temp"
if [[ ! -e $user_temp_dir ]]; then
    mkdir $user_temp_dir
fi

# Rendering
view_mode="library"
search_filter_enabled=0
search_query=""
is_running=1
force_redraw=1

print_middle_screen "$GREEN" "Loading library..."

# Fetch library
library=$(mktemp)
library_cache="$user_temp_dir/library_cache"
library_search_cache="$user_temp_dir/library_search_cache"

# Pagination
page=0
page_length=7
library_length=0
total_pages=1

# Save library to cache

#Arguments: "mode"
print_commands() {
    if [[ $1 == "library" ]]; then
        print_highlight "(g) Navigate topbar (s) Search library (j) Scroll down (k) Scroll up" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
        print_highlight "(p) <number> Play playlist (v) <number> View playlist" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
    else
        echo -e "Unknown view mode\n\n"
    fi
}

cache_library() {
    "$PROJECT_ROOT/bin/spoticli" library $USER_ID -r -C -l 50 > "$library"
    : > "$library_cache"
    index=1
    cat "$library" | jq -r '.[] | "\(.uri)::\(.name)"' | while IFS= read -r fields; do
        echo "${index}::${fields}" >> "$library_cache"
        ((++index))
    done
    library_length=$(jq -r 'length' "$library")
    total_pages=$(( library_length / page_length ))
    if (( library_length % page_length != 0 )); then
        ((++total_pages))
    fi
}

# Instantiate cache
cache_library


while [[ "$is_running" -ne 0 ]]; do
    if [[ "$force_redraw" -eq 1 ]]; then
        clear
        draw_topbar 1
        print_commands "$view_mode"

        filtered=""

        if [[ "$search_query" != "" ]]; then
            set_bottom_bar "Results for: '$search_query'"
            # Filter library results
            search_uris=$(jq -Rs 'split("\n") | map(select(length > 0))' "$library_search_cache")
            filtered=$(jq -cn --argjson search_uris "$search_uris" --slurpfile library "$library" '$library[0] | map(select(.uri | IN($search_uris[])))')
            
            # Modify the library cache
            : > "$library_cache"
            index=1
            echo "$filtered" | jq -r '.[] | "\(.uri)::\(.name)"' | while IFS= read -r fields; do
                echo "${index}::${fields}" >> "$library_cache"
                ((++index))
            done
            total_items=$(jq -r 'length' <<< "$filtered")
            total_pages=$(( total_items / page_length ))
            if (( total_items % page_length != 0 )); then
                ((++total_pages))
            fi

        else
            filtered=$(cat "$library")
        fi

        paginated=$(jq -c ".[$((page * page_length)):$((page * page_length + page_length - 1))]" <<< "$filtered")

        echo -e "\n"
        print_highlight "Page $(( page + 1 )) / $total_pages" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
        # Display library based on pagination
        print_playlist "$paginated" $(( SCREEN_WIDTH / 8 )) $(( SCREEN_WIDTH / 8 * 6 )) -1 $(( page * page_length )) 

        force_redraw=0
    fi

    # Render results

    read -rsn1 key
    if [[ $key == $'g' ]]; then
        # Handle escape pressed
        is_running=0
    fi

    case $key in
        's')
            # Arguments "bottom_prefix" <max_number> <ptr>
            get_text_dialogue "search library: " search_query

            if [[ "$search_query" != "" ]]; then
                # Get the items that match the search and store them in the search cache
                awk -F'::' "\$3 ~ /$search_query/ {print \$2}" "$library_cache" > "$library_search_cache"

                search_filter_enabled=1
                page=0
                force_redraw=1
            fi

           ;;
        $'\e')
            if [[ "$search_query" != "" ]]; then
                # Reset cache to original
                cache_library

                search_query=""
                search_filter_enabled=0
                force_redraw=1
            fi
            ;;
        # Pagination & movement
        'n'|'j'|'l')
            page=$(( ( page + 1 ) % total_pages ))
            force_redraw=1
            ;;
        'b'|'k'|'h')
            page=$(( ( page - 1 + total_pages ) % total_pages ))
            force_redraw=1
            ;;
        'p')
            get_number_dialogue "p" "$library_length" number
            playlist_uri=$(awk -F'::' "/^${number}::/ {print \$2}" "$library_cache")
            status=$("$PROJECT_ROOT/bin/spoticli" streamstate "$USER_ID" -o 1 -C "$playlist_uri")
            
            if [[ "$status" -eq 204 ]]; then
                set_bottom_bar "Now playing playlist number ${number} from position 0"
            else
                error_message "Action failed with status $status"
            fi
           ;;
    esac

done

rm "$library"
exit 0
