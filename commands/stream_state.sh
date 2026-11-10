#!/bin/bash

# Arguments "user_id" [OPTIONS]
# OPTIONS:
#   -c: currently playing
#   -T "uri": play track
#   -P: pause music
#   -R: resume music
#   -B: back (previous track)
#   -N: next track
#   -S "0|1": set shuffle
#   -Q "uri": queue song

USER_ID=$1
# Pop the user ID off so the flags work correctly
shift

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/get_token.sh"
source "$PROJECT_ROOT/lib/requests.sh"

token=$(get_token $USER_ID)

is_silent=0

while getopts ":scqPRBNS:Q:T:" opt; do
    case "$opt" in
        's')
            is_silent=1
            ;;
        'c')
            currently_playing $token
            ;;
        'q')
            get_queue $token
            ;;
        'P')
            pause_music $token

            if [[ $is_silent -eq 1 ]] then
                exit 0
            else
                exit $?
            fi
            ;;
        'R')
            play_music $token

            if [[ $is_silent -eq 1 ]] then
                exit 0
            else
                exit $?
            fi
            ;;
        'B')
            previous_track $token

            if [[ $is_silent -eq 1 ]] then
                exit 0
            else
                exit $?
            fi
            ;;      
        'N')
            next_track $token

            if [[ $is_silent -eq 1 ]] then
                exit 0
            else
                exit $?
            fi
            ;;
        'S')
            is_shuffle=$OPTARG
            if [[ $is_shuffle != 0 && $is_shuffle != 1 ]]; then
                echo "Error: stream_state -S: parameter must be 0 or 1"
                exit 1
            fi

            set_shuffle $token $is_shuffle

            if [[ $is_silent -eq 1 ]] then
                exit 0
            else
                exit $?
            fi
            ;;
        'Q')
            uri=$OPTARG
            queue_song "$token" "$uri"
            ;;
        'T')
            uri=$OPTARG
            set_playback_track "$token" "$uri"
            ;;
     esac
done
