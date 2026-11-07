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
prev_queue=""

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
        print_highlight "(g) Navigate topbar (p) Pause/play    (n) Next track    (b) Previous track" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
        print_highlight "(s) Toggle shuffle (q) View queue" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
    elif [[ $1 == "queue" ]]; then
        print_highlight "(g) Navigate topbar (q) View now playing (n) Next page (b) Previous page" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
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

    # ===== Fetch data =====

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
    uri=$(jq -r '.item.uri' < "$response")
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
        cat $response
        rm $response
        read -rs
        exit 1
    fi

    # Unqueue logic for skipping songs

    if [[ "${prev_name}" != "${name}" ]]; then
        # Check unqueue list to see if we need to skip
        unqueue_cache="$user_temp_dir/unqueue_cache"
        if grep -q "$uri" "$unqueue_cache"; then
            # Skip the song
            "$PROJECT_ROOT/bin/spoticli" streamstate $USER_ID -N

            echo -e "Skipping song $uri\nUnqueue length: $(wc -l "$unqueue_cache")"

            # Remove the song from the unqueue
            sed -i "/$uri/d" "$unqueue_cache"
            echo -e "Unqueue length POST: $(wc -l "$unqueue_cache")"
        fi

        # Force a queue redraw to update the queue, now that a new song is playing
        if [[ "$view_mode" == "queue" ]]; then
            prev_name="$name"
            force_queue_redraw=1
        else
            force_now_playing_redraw=1
        fi
    fi

    if [[ $view_mode == "now-playing" || $force_now_playing_redraw -eq 1 ]]; then
        
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

        # File to cache the user's queue (so we can reference it while they do actions)
        queue_cache="$user_temp_dir/queue_cache" || return 1
        unqueue_cache="$user_temp_dir/unqueue_cache"
        if [[ ! -f $unqueue_cache ]]; then
            touch $unqueue_cache
        fi
        unqueue_uris=$(jq -Rsc 'split("\n") | map(select(length > 0))' "$unqueue_cache")

        # Temp file for the response
        response=$(mktemp)

        if [[ ! -s "$response" ]]; then
            "$PROJECT_ROOT/bin/spoticli" streamstate "$USER_ID" -q > "$response"
        fi

        # Parse out the info
        currently_playing=$(jq -c '.currently_playing' "$response")
        cp_uri=$(jq -c '.currently_playing.uri' "$response")
        queue=$(jq -c --argjson unqueue_uris "$unqueue_uris" ".queue | map(select(.uri as \$u | \$unqueue_uris | index(\$u) | not)) | .[${queue_offset}:$(( queue_offset + queue_page_size ))]" "$response")

        # Cache the queue to a file for later
        # Put the currently playing track in as the 0 index just because
        echo "0::$cp_uri" > "$user_temp_dir/queue_cache"
        index=1
        while IFS= read -r song; do
            uri=$(echo "$song" | jq -r ".uri")
            echo "${index}::${uri}" >> "$user_temp_dir/queue_cache"
            ((++index))
        done < <(jq -c ".queue[]" "$response")

        queue_total_size=$index

        echo -e "\n"

        print_highlight "Now Playing" 1 "$VIOLET" $SCREEN_WIDTH "center"
        print_song "$currently_playing" $(( SCREEN_WIDTH / 8 )) $(( SCREEN_WIDTH / 8 * 6 )) 0 -1

        print_highlight "Page $(( ( queue_offset / queue_page_size ) + 1 )) / $(( queue_total_size / queue_page_size ))" 1 "$CHARCOAL" $SCREEN_WIDTH "center"

        print_songs "$queue" $(( SCREEN_WIDTH / 8 )) $(( SCREEN_WIDTH / 8 * 6 )) -1 $queue_offset

        force_queue_redraw=0
    fi

    # Wait 3 seconds and accept keyboard input in this time
    wait_time=2
    # Wait longer if it's in queue mode because we don't need to update the screen as frequently
    if [[ "$view_mode" == "queue" ]]; then
        wait_time=4
    fi
    read -r -s -n 1 -t $wait_time key

    if [[ $key == $'g' ]]; then
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
                if (( queue_offset + queue_page_size < queue_total_size )); then
                    ((queue_offset+=$queue_page_size))
                else
                    queue_offset=0
                fi
                force_queue_redraw=1
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
                else
                    queue_offset=$(( queue_total_size - queue_page_size + (queue_total_size % queue_page_size) ))
                fi
                force_queue_redraw=1
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
        'd')
            set_bottom_bar "d"
            if [[ "$view_mode" == "queue" ]]; then
                read -rs -n 1 digit_1
                set_bottom_bar "d${digit_1}"
                sleep 0.1

                # Make sure they are typing a number
                if [[ ! "$digit_1" =~ [0-9] || "$digit_1" -eq 0 ]]; then
                    # If they aren't typing a number, continue
                    continue
                fi
                # If the user could still be typing more digits.. wait for that digit
                number=0
                if (( digit_1 * 10 < queue_total_size )); then
                    set_bottom_bar "d${digit_1}        Enter to finish"
                    read -rs -n 1 digit_2
                    if [[ "$digit_2" == "" ]]; then
                        number="$digit_1"
                    elif [[ ! "$digit_2" =~ [0-9] ]]; then
                        # If they aren't typing a number, continue
                        continue
                    else
                        number=$(( digit_1 * 10 + digit_2))
                    fi
                else
                    number="$digit_1"
                fi
                set_bottom_bar "d$number"

                # Define files
                queue_cache="$user_temp_dir/queue_cache"
                unqueue_cache="$user_temp_dir/unqueue_cache"
                logical_queue=$(mktemp)

                # Convert the user-given number to the corresponding number in the queue cache, by adding the number of unqueued songs before this track
                skipped_count=0
                index=0
                while read -r line; do
                    line_id=$(echo $line | awk -F'::' '{print $2}')
                    # If the track has been unqueued, increment the skipped values
                    if grep -q "$line_id" $unqueue_cache; then
                        ((++skipped_count))
                    # Otherwise, add it to the logical queue
                    else
                        echo "$(( index - skipped_count ))::$line_id" >> $logical_queue
                    fi
                    ((++index))
                done < $queue_cache

                # Find the track ID in the queue cache
                id=$(awk -F'::' "/^${number}/ {print \$2}" "$logical_queue")
                logical_num=$(awk -F'::' "/^${number}/ {print \$1}" "$logical_queue")

                # Insert the removed value into the unqueue cache
                echo "$id" >> $unqueue_cache

                rm $logical_queue

                # Redraw the queue
                force_queue_redraw=1
            fi
            ;;
        'a')
            # Add a song to the queue

            # Open the text bar
            set_bottom_bar "a <search>"

            ;;
        $'\e')
            set_bottom_bar ""
            ;;
        *)
            # If they type an unaccepted key, clear the line
            ;;
    esac
done

