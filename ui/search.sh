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

# Clear user's search_cache
:> "$user_temp_dir/search_cache"

# Search constants
search_length=5

# Rendering
view_mode="search"
is_running=1
force_search_redraw=1

#Arguments: "mode"
print_commands() {
    if [[ $1 == "search" ]]; then
        print_highlight "(g) Navigate topbar (s) Search query (j) Scroll down (k) Scroll up" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
        print_highlight "(p) <number> Play song (a) <number> Queue song (enter) Select search option" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
    else
        echo -e "Unknown view mode\n\n"
    fi
}

while [[ "$is_running" -ne 0 ]]; do
    if [[ "$force_search_redraw" -eq 1 ]]; then
        clear
        draw_topbar 0
        print_commands $view_mode

        if [[ ! -s "$user_temp_dir/search_cache" ]]; then
            num_rows=$(tput lines)
            for (( i=0; i < num_rows / 5 * 2; i++)); do echo -en "\n"; done;
            print_highlight "No search results." 1 "$VIOLET" "$SCREEN_WIDTH" "center"
            print_highlight "Press 's' to enter search mode." 1 "$VIOLET" "$SCREEN_WIDTH" "center"
        fi
    fi

    # Render results

    read -rsn1 key
    if [[ $key == $'g' ]]; then
        # Handle escape pressed
        exit 0
    fi

    case $key in
        's')
            query=""
            still_typing=1
            user_canceled=0
            set_bottom_bar "search: "
            while [[ "$still_typing" -eq 1 && "$user_canceled" -ne 1 ]]; do
                IFS= read -rsn1 next_letter
                # If they hit enter
                if [[ -z "$next_letter" ]]; then
                    still_typing=0
                    continue
                fi
                if [[ "$next_letter" == $'\e' ]]; then
                    set_bottom_bar ""
                    user_canceled=1
                    break
                fi
                if [[ "$next_letter" == $'\x7f' || "$next_letter" == $'\x08' ]]; then
                    query="${query%?}"
                else
                    query+=$next_letter
                fi
                set_bottom_bar "search: $query"
            done

            if [[ "$user_canceled" -ne 1 ]]; then

                # Load response
                response=$(mktemp)
                "$PROJECT_ROOT/bin/spoticli" search "$USER_ID" -q "$query" > "$response"
                tracks=$(jq -c ".tracks.items" < "$response")

                # Print songs
                clear
                draw_topbar 0
                print_commands "$view_mode"
                print_songs "$tracks" $(( SCREEN_WIDTH / 8 )) $(( SCREEN_WIDTH / 8 * 6 )) -1 0
                # Save the songs to the search cache in case they want to select one
                index=1
                echo "" > "$user_temp_dir/search_cache"
                while IFS= read -r song; do
                    uri=$(jq -r '.uri' <<< "$song")
                    echo "${index}::${uri}" >> "$user_temp_dir/search_cache"
                    ((++index))
                done < <( echo "$tracks" | jq -c '.[]' )

                force_search_redraw=0
            fi
            ;;
        'j')

            ;;
        'k')

            ;;
        'p')
            if [[ ! -s "$user_temp_dir/search_cache" ]]; then
                set_bottom_bar "No search results to query"
                read -r
            else
                set_bottom_bar "p"
                get_number_dialogue "p" search_length number

                if [[ "$number" -lt 1 ]]; then
                    continue
                fi

                # Get track URI from cache
                uri=$(awk -F'::' "/^${number}/ { print \$2 }" "$user_temp_dir/search_cache")

                response=$("$PROJECT_ROOT/bin/spoticli" streamstate "$USER_ID" -T "$uri")

                if [[ "$response" -eq 204 ]]; then
                    set_bottom_bar "Now playing number ${number}. Press any key to continue."
                    read -rsn1
                    set_bottom_bar ""
                else 
                    set_bottom_bar "Error playing song"
                fi
            fi
            ;;
        'a')
            if [[ ! -s "$user_temp_dir/search_cache" ]]; then
                set_bottom_bar "No search results to query"
                read -r
            else
                set_bottom_bar "a"
                get_number_dialogue "a" search_length number

                # Validate input
                if [[ "$number" -lt 1 ]]; then
                    continue
                fi

                # Get track URI from cache
                uri=$(awk -F'::' "/^${number}/ { print \$2 }" "$user_temp_dir/search_cache")

                response=$("$PROJECT_ROOT/bin/spoticli" streamstate "$USER_ID" -Q "$uri")

                set_bottom_bar "Added number ${number} to queue. Press any key to continue."
                read -rsn1
                set_bottom_bar ""
            fi
            ;;
    esac

done
