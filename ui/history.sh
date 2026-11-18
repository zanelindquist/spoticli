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
view_mode="history"
force_redraw=1
is_running=1

print_middle_screen "$GREEN" "Loading history..."

# Hold numbers for selection
history_cache="$user_temp_dir/history_cache"
# Hold cached history
current_history="$user_temp_dir/current_history"

# Pagination
page=0
page_length=7
history_length=0
total_pages=1

# Save library to cache

#Arguments: "mode"
print_commands() {
    if [[ "$1" == "history" ]]; then
        print_highlight "(g) Navigate topbar (j) Scroll down (k) Scroll up" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
        print_highlight "(p) <number> Play track (r) Refresh page" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
    else
        echo -e "Unknown view mode\n\n"
    fi
}

cache_history() {
    "$PROJECT_ROOT/bin/spoticli" history $USER_ID -h -l 20 > "$current_history"
    uris=$(jq -r '.items[].track.uri' "$current_history")
    : > "$history_cache"
    index=1
    echo "$uris" | while IFS= read -r uri; do
        echo "${index}::${uri}" >> "$history_cache"
        ((++index))
    done
    history_length=$(jq -r '.total' "$current_history")
    total_pages=$(( history_length / page_length ))
    if (( history_length % page_length != 0 )); then
        ((++total_pages))
    fi
}

# Instantiate cache
cache_history

while [[ "$is_running" -ne 0 ]]; do
    if [[ "$force_redraw" -eq 1 ]]; then
        clear
        draw_topbar 1
        print_commands "$view_mode"

        items=$(jq -c ".items[$((playlist_page * page_length)):$((page * page_length + page_length - 1))] | map(.track)" "$current_history")

        echo -e "\n"
        print_highlight "Page $(( playlist_page + 1 )) / $total_pages" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
        echo -e "\n"
        print_highlight "Listening History" 1 "$VIOLET" $SCREEN_WIDTH "center"
        # Display library based on pagination
        print_songs "$items" $(( SCREEN_WIDTH / 8 )) $(( SCREEN_WIDTH / 8 * 6 )) -1 $(( playlist_page * page_length )) 

    fi

    # Render results
    read -rsn1 key
    if [[ $key == $'g' ]]; then
        # Handle escape pressed
        is_running=0
    fi

    case $key in
       # Pagination & movement
        'r')
            cache_history
            force_redraw=1
            ;;
        'n'|'j'|'l')
            if [[ "$view_mode" == "history" ]]; then
                page=$(( ( page + 1 ) % total_pages ))
                force_redraw=1
            fi
            ;;
        'b'|'k'|'h')
            if [[ "$view_mode" == "history" ]]; then
                page=$(( ( page - 1 + total_pages ) % total_pages ))
                force_redraw=1
            fi
            ;;
        'p')
            if [[ "$view_mode" == "history" ]]; then
                get_number_dialogue "p" "$history_length" number
                track_uri=$(awk -F'::' "/^${number}::/ {print \$2}" "$history_cache")
                status=$("$PROJECT_ROOT/bin/spoticli" streamstate "$USER_ID" -T "$track_uri")

                if [[ "$status" -eq 204 ]]; then
                    set_bottom_bar "Now playing track number $number"
                else
                    error_message "Action failed with status $status"
                fi

            fi
           ;;
    esac

done

exit 0
