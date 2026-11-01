#!/bin/bash

USER_ID=$1
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"
source "$PROJECT_ROOT/lib/images.sh"
source "$PROJECT_ROOT/ui/topbar.sh"

is_running=1
prev_album_image=""
prev_progress_ms=-1
prev_name=""

while [[ $is_running -ne 0 ]]; do
    response=$(mktemp)

    "$PROJECT_ROOT/bin/spoticli" streamstate $USER_ID -c > "$response"

    name=$(jq -r '.item.name' < "$response")
    artists=$(jq -r '[.item.artists[].name] | join(", ")' < $response)
    image_url=$(jq -r '.item.album.images[-1].url' < $response)

    progress_ms=$(jq -r '.progress_ms' < $response)
    duration_ms=$(jq -r '.item.duration_ms' < $response)
    progress_width_ratio=1.5
    left_progress_indent=$( echo "($SCREEN_WIDTH - $SCREEN_WIDTH / $progress_width_ratio) / 2" | bc )
    progress_bars=$( echo "($SCREEN_WIDTH / $progress_width_ratio) * $progress_ms / $duration_ms" | bc )
    progress_bars_remaining=$( echo "($SCREEN_WIDTH / $progress_width_ratio) - $progress_bars - 1" | bc )

    # Print stuff
    # Check if we need to redraw entire screen
    if [[ $prev_album_image != $image_url ]]; then
        prev_album_image=$image_url
        prev_progress_ms=-1
        clear
        draw_topbar 2
        echo -e "\n\n"
        indent_image $image_url $(( SCREEN_WIDTH / 2 )) $(( SCREEN_WIDTH / 4 )) 1
        echo;
    # Otherwise, erase the last couple of lines and just redraw the progress
    fi

    if [[ $prev_progress_ms -eq -1 ]]; then
        echo -e "\n\n\n"
    fi

    # Only redraw the bar if the track's progress has changed
    if [[ $prev_progress_ms -ne $progress_ms ]]; then
        prev_progress_ms=$progress_ms

        # If we need to redraw the name
        if [[ "${prev_name}" != "${name}" ]]; then
            prev_name=$name

            # Clear up 4 lines
            printf "\e[4A\e[J"
            # Now redraw progress bar
            printf "\n%*s|" "$left_progress_indent" "";
            print_bars $progress_bars ""
            printf "⊙"
            printf "$CHARCOAL"
            print_bars $progress_bars_remaining ""
            printf "${RESET}|\n"

            echo -e "\n";
            print_highlight "$name" 1 "$VIOLET" $SCREEN_WIDTH "center"
            print_highlight "$artists" 1 "$VIOLET" $SCREEN_WIDTH "center"
        else

            # Go up 4 lines and clear it
            printf "\033[s\033[5A\033[K"

            printf "\n%*s|" "$left_progress_indent" "";
            print_bars $progress_bars ""
            printf "⊙"
            printf "$CHARCOAL"
            print_bars $progress_bars_remaining ""
            printf "${RESET}|\n"

            # Restore cursor position
            printf "\e[u"

       fi
    fi

       rm $response

    sleep 3

done

