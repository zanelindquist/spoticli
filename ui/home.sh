#!/bin/bash

USER_ID=$1
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"
source "$PROJECT_ROOT/lib/images.sh"
source "$PROJECT_ROOT/lib/components.sh"
source "$PROJECT_ROOT/ui/topbar.sh"

# Load up the user's temporary directory
user_temp_dir="$PROJECT_ROOT/data/users/$USER_ID/temp"
if [[ ! -e $user_temp_dir ]]; then
    mkdir $user_temp_dir
fi

# Render optimization variables
is_running=1
prev_album_image=""
prev_progress_ms=-1
prev_name=""

view_mode="now-playing"
force_now_playing_redraw=0
force_queue_redraw=0

current_line=1
progress_bar_line_num=0

# Player variables
is_playing=1
is_shuffle=0

queue_offset=0
queue_page_size=5
queue_total_size=20

#Arguments: "mode" is_playing? is_shuffle?
print_commands() {
    if [[ $1 == "now-playing" ]]; then
        print_highlight "(esc) Navigate topbar (p) Pause/play    (n) Next track    (b) Previous track" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
        print_highlight "(s) Toggle shuffle (q) View queue" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
    elif [[ $1 == "queue" ]]; then
        print_highlight "(esc) Navigate topbar (q) View now playing (n) Next page (b) Previous page" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
        print_highlight "(d) <number>? Remove track from queue (a) Insert song into queue" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
    else
        echo -e "Unknown view mode\n\n"
    fi

    print_highlight "playing" $2 $GREEN_BLACK $(( SCREEN_WIDTH / 2 )) "right"
    echo -en "    "
    print_highlight "shuffle" $3 $GREEN_BLACK $(( SCREEN_WIDTH / 2 )) "left"

    ((current_line+=2))
}

print_progress_bar() {
    printf "\n%*s|" "$left_progress_indent" ""
    print_bars $progress_bars ""
    printf "⊙"
    printf "$CHARCOAL"
    print_bars $progress_bars_remaining ""
    printf "${RESET}|\n"
}


while [[ $is_running -ne 0 ]]; do
    if [[ $view_mode == "now-playing" || $force_now_playing_redraw -eq 1 ]]; then
        response=$(mktemp) || return 1

        "$PROJECT_ROOT/bin/spoticli" streamstate "$USER_ID" -c > "$response"

        # Check if file still exists
        if [[ ! -f "$response" ]]; then
            echo "Client closed. Temp file could not be located"
            exit 1
        fi

        # Check if file is empty
        if [[ ! -s "$response" ]]; then
            echo "Error: No response body for file"
            rm -f "$response"
            exit 1
        fi

        name=$(jq -r '.item.name' < "$response")
        artists=$(jq -r '[.item.artists[].name] | join(", ")' < $response)
        image_url=$(jq -r '.item.album.images[-1].url' < $response)
        is_playing=$(jq -r '.is_playing' < $response)
        if [[ $is_playing == "true" ]]; then is_playing=1; else is_playing=0; fi

        progress_ms=$(jq -r '.progress_ms' < $response)
        duration_ms=$(jq -r '.item.duration_ms' < $response)
        progress_width_ratio=1.5
        left_progress_indent=$( echo "($SCREEN_WIDTH - $SCREEN_WIDTH / $progress_width_ratio) / 2" | bc )
        progress_bars=$( echo "($SCREEN_WIDTH / $progress_width_ratio) * $progress_ms / $duration_ms" | bc )
        progress_bars_remaining=$( echo "($SCREEN_WIDTH / $progress_width_ratio) - $progress_bars - 1" | bc )

        if [[ -v $name || "$name" == "" ]]; then
            echo "No currently playing song"
            read -rs
            exit 1
        fi

        # Print stuff
        # Check if we need to redraw entire screen
        if [[ $prev_album_image != $image_url || $force_now_playing_redraw -eq 1 ]]; then
            prev_album_image=$image_url
            prev_progress_ms=-1

            clear
            current_line=1
            draw_topbar 2
            ((current_line+=3))

            print_commands $view_mode $is_playing $is_shuffle
            echo -e "\n\n"
            indent_image $image_url $(( SCREEN_WIDTH / 2 )) $(( SCREEN_WIDTH / 4 )) 1
            echo;
            ((current_line+=( SCREEN_WIDTH / 2) + 2 + 1 ))
        # Otherwise, erase the last couple of lines and just redraw the progress
        fi

        # If this is the first iteration, then write blank space
        if [[ $prev_progress_ms -eq -1 ]]; then
            echo -e "\n\n\n"
        fi

        # Only redraw the bar if the track's progress has changed
        if [[ $prev_progress_ms -ne $progress_ms || $force_now_playing_redraw -eq 1 ]]; then
            prev_progress_ms=$progress_ms

            # If we need to redraw the name
            if [[ "${prev_name}" != "${name}" || $force_now_playing_redraw -eq 1 ]]; then
                prev_name=$name

                # Clear up 4 lines to the bottom
                printf "\e[4A\e[J"
                # Now redraw progress bar
                printf "\n%*s|" "$left_progress_indent" ""
                print_bars $progress_bars ""
                printf "⊙"
                printf "$CHARCOAL"
                print_bars $progress_bars_remaining ""
                printf "${RESET}|\n"

                echo -e "\n";
                print_highlight "$name" 1 "$VIOLET" $SCREEN_WIDTH "center"
                print_highlight "$artists" 1 "$VIOLET" $SCREEN_WIDTH "center"

                # Reload queue cache
                "$PROJECT_ROOT/bin/spoticli" streamstate "$USER_ID" -q > "$user_temp_dir/queue"
            else

                # Go up 4 lines and clear only it
                printf "\e[s\e[5A\e[K"

                printf "\n%*s|" "$left_progress_indent" "";
                print_bars $progress_bars ""
                printf "⊙"
                printf "$CHARCOAL"
                print_bars $progress_bars_remaining ""
                printf "${RESET}|\n"

                # Restore cursor position
                printf "\e[u"

            fi
            force_now_playing_redraw=0
        fi

        # Remove temp file
        rm $response

    elif [[ "$view_mode" == "queue" && "$force_queue_redraw" -eq 1 ]]; then
        clear

        draw_topbar 2
        print_commands $view_mode $is_playing $is_shuffle

        response="$user_temp_dir/queue" || return 1

        if [[ ! -s "$response" ]]; then
            "$PROJECT_ROOT/bin/spoticli" streamstate "$USER_ID" -q > "$response"
        fi

        currently_playing=$(jq -c '.currently_playing' "$response")
        queue=$(jq -c ".queue[${queue_offset}:$(( queue_offset + queue_page_size ))]" "$response")

        echo -e "\n"

        print_highlight "Page $(( ( queue_offset / queue_page_size ) + 1 )) / $(( queue_total_size / queue_page_size ))" 1 "$CHARCOAL" $SCREEN_WIDTH "center"


        print_songs "$queue" $(( SCREEN_WIDTH / 8 )) $(( SCREEN_WIDTH / 8 * 6 )) -1 $queue_offset

        force_queue_redraw=0
    fi

    # Wait 3 seconds and accept keyboard input in this time
    read -r -s -n 1 -t 3 key

    if [[ $key == $'\e' ]]; then
        # Check for other characters being pressed (i.e. an arrow key)
        read -s -n 2 -t 0.002 next_chars

        if [[ -z $next_chars ]]; then
            # Handle escape pressed
            exit 0
        fi
    fi

    case $key in
        'p')
            if [[ $is_playing -eq 1 ]]; then
                status=$("$PROJECT_ROOT/bin/spoticli" streamstate $USER_ID -P)
                is_playing=0
            else
                status=$("$PROJECT_ROOT/bin/spoticli" streamstate $USER_ID -R)
                is_playing=1
            fi

            if [[ $status -eq 200 ]]; then
                printf "\e[4;0H\e[K\e[K"
                print_commands $view_mode $is_playing $is_shuffle
                # Restore cursor position
                printf "\e[u"
            fi
            ;;
        'n')
            if [[ "$view_mode" == "now-playing" ]]; then
                status=$("$PROJECT_ROOT/bin/spoticli" streamstate $USER_ID -N)
            elif [[ "$view_mode" == "queue" ]]; then
                if (( queue_offset + queue_page_size < $queue_total_size )); then
                    ((queue_offset+=$queue_page_size))
                    force_queue_redraw=1
                fi
            else
                echo -e "Unknown view mode\n"
            fi
            ;;
        'b')
            if [[ "$view_mode" == "now-playing" ]]; then
                status=$("$PROJECT_ROOT/bin/spoticli" streamstate $USER_ID -B)
            elif [[ "$view_mode" == "queue" ]]; then
                if (( queue_offset - queue_page_size >= 0 )); then
                    ((queue_offset-=$queue_page_size))
                    force_queue_redraw=1
                fi
            else
                echo -e "Unknown view mode\n"
            fi
            ;;
        's')

            status=$("$PROJECT_ROOT/bin/spoticli" streamstate $USER_ID -S $is_shuffle)
            if [[ $status -eq 200 ]]; then
                printf "\e[4;0H\e[K\e[K"
                print_commands $view_mode $is_playing $is_shuffle
                # Restore cursor position
                printf "\e[u"

                is_shuffle=$(( (is_shuffle + 1) % 2))
            fi
            ;;
        'q')
            if [[ "$view_mode" == "now-playing" ]]; then
                view_mode="queue"
                force_queue_redraw=1
            else
                view_mode="now-playing"
                force_now_playing_redraw=1
            fi
            ;;

    esac
done

