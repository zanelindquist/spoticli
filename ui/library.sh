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
playlist_name=""

print_middle_screen "$GREEN" "Loading library..."

# Fetch library
library=$(mktemp)
library_cache="$user_temp_dir/library_cache"
library_search_cache="$user_temp_dir/library_search_cache"
# Hold a current playlist that we're viewing
current_playlist="$user_temp_dir/current_playlist"
playlist_search_cache="$user_temp_dir/playlist_search_cache"
# Pagination
page=0
page_length=7
library_length=0
total_pages=1
playlist_page=0
playlist_length=0
playlist_total_pages=1

# Save library to cache

#Arguments: "mode"
print_commands() {
    if [[ $1 == "library" || $1 == "playlist" ]]; then
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

        if [[ "$view_mode" == "library" ]]; then
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
                library_length=$(jq -r 'length' <<< "$filtered")
                total_pages=$(( library_length / page_length ))
                if (( library_length % page_length != 0 )); then
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

        elif [[ "$view_mode" == "playlist" ]]; then
            # Digest playlist cache
            items=$(jq -c "[.items[].item][$((playlist_page * page_length)):$((playlist_page * page_length + page_length - 1))]" "$current_playlist")

            echo -e "\n"
            print_highlight "Page $(( playlist_page + 1 )) / $playlist_total_pages" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
            echo -e "\n"
            print_highlight "$playlist_name" 1 "$VIOLET" $SCREEN_WIDTH "center"
            # Display library based on pagination
            print_songs "$items" $(( SCREEN_WIDTH / 8 )) $(( SCREEN_WIDTH / 8 * 6 )) -1 $(( playlist_page * page_length )) 
        fi

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
                view_mode="library"
            fi

           ;;
        $'\e'|'q')
            if [[ "$view_mode" == "library" ]]; then
                if [[ "$search_query" != "" ]]; then
                    # Reset cache to original
                    cache_library

                    search_query=""
                    search_filter_enabled=0
                    force_redraw=1
                fi
            elif [[ "$view_mode" == "playlist" ]]; then
                view_mode="library"
                force_redraw=1
            fi
            ;;
        # Pagination & movement
        'n'|'j'|'l')
            if [[ "$view_mode" == "library" ]]; then
                page=$(( ( page + 1 ) % total_pages ))
            elif [[ "$view_mode" == "playlist" ]]; then
                # TODO: HANDLE PAGINATION LIMITS RUNNING OUT
                playlist_page=$(( ( playlist_page + 1 ) % playlist_total_pages ))
            fi
            force_redraw=1
            ;;
        'b'|'k'|'h')
            if [[ "$view_mode" == "library" ]]; then
                page=$(( ( page - 1 + total_pages ) % total_pages ))
            elif [[ "$view_mode" == "playlist" ]]; then
                playlist_page=$(( ( playlist_page - 1 + playlist_total_pages ) % playlist_total_pages ))
            fi
            force_redraw=1
            ;;
        'p')
            if [[ "$view_mode" == "library" ]]; then
                get_number_dialogue "p" "$library_length" number
                playlist_uri=$(awk -F'::' "/^${number}::/ {print \$2}" "$library_cache")
                status=$("$PROJECT_ROOT/bin/spoticli" streamstate "$USER_ID" -o 1 -C "$playlist_uri")
                
                if [[ "$status" -eq 204 ]]; then
                    set_bottom_bar "Now playing playlist number ${number} from position 0"
                else
                    error_message "Action failed with status $status"
                fi
            elif [[ "$view_mode" == "playlist" ]]; then
                get_number_dialogue "p" "$playlist_length" number
                track_uri=$(awk -F'::' "/^${number}::/ {print \$2}" "$playlist_search_cache")
                playlist_uri=$(jq -r '.href' "$current_playlist" | cut -d'/' -f6)
                status=$("$PROJECT_ROOT/bin/spoticli" streamstate "$USER_ID" -o "$track_uri" -t "uri" -C "spotify:playlist:$playlist_uri")

                if [[ "$status" -eq 204 ]]; then
                    set_bottom_bar "Now playing playlist from position $number"
                else
                    error_message "Action failed with status $status"
                fi

            fi
           ;;
        'v')
            if [[ "$view_mode" == "library" ]]; then
                get_number_dialogue "v" "$library_length" view_number
                playlist_uri=$(awk -F'::' "/^${view_number}::/ {print \$2}" "$library_cache" | awk -F: '{print $3}')
                playlist_name=$(awk -F'::' "/^${view_number}::/ {print \$3}" "$library_cache")

                # See if we already have it cached or not
                # If current playlist is empty or we dont have the right one cached
                cached_uri=$(jq -r '.href' "$current_playlist" | cut -d'/' -f6)
                if [[ ! -s "$current_playlist"  || "$cached_uri" != "$playlist_uri" ]]; then
                    # Get the playlist
                    response=$("$PROJECT_ROOT/bin/spoticli" library "$USER_ID" -t "$playlist_uri")
                    # Save and overwrite the response to the cache
                    echo "$response" > "$current_playlist"
                    playlist_length=$(jq -r '.total' <<< "$response")
                    playlist_total_pages=$(( playlist_length / page_length ))
                    if (( playlist_length % page_length != 0 )); then
                        ((++playlist_total_pages))
                    fi

                    # Write the playlist to the playlist_search_cache
                    index=1
                    : > "$playlist_search_cache"
                    while IFS= read -r song_uri; do
                        echo "$index::$song_uri" >> "$playlist_search_cache"
                        ((++index))
                    done < <(jq -r '.items[].item.uri' <<< "$response")
                else
                    playlist_length=$(jq -r '.total' < "$current_playlist")
                    playlist_total_pages=$(( playlist_length / page_length ))
                    if (( playlist_length % page_length != 0 )); then
                        ((++playlist_total_pages))
                    fi
                fi
                
                view_mode="playlist"
                force_redraw=1
            else
                set_bottom_bar "You cannot use 'v' in mode '$view_mode'. Press any key to continue..."
                read -rsn1
                set_bottom_bar ""
            fi
            ;;
        'a')
            if [[ "$view_mode" == "library" ]]; then
                set_bottom_bar "Error: cannot queue songs in library view. Press any key to continue..."
                read -rsn1
            elif [[ "$view_mode" == "playlist" ]]; then
                get_number_dialogue "a" "$playlist_length" number
                track_uri=$(awk -F'::' "/^${number}::/ {print \$2}" "$playlist_search_cache")
                status=$("$PROJECT_ROOT/bin/spoticli" streamstate "$USER_ID" -Q "$track_uri")

                if [[ $? -eq 0 ]]; then
                    set_bottom_bar "Queued song at position $number"
                else
                    error_message "Action failed with status $status"
                fi

            fi
           ;;
 
    esac

done

rm "$library"
exit 0
