#!/bin/bash

# Arguments "user_id" [OPTIONS]
# OPTIONS:
#   -c: currently playing
#   -P: pause music
#   -R: resume music
#   -B: back (previous track)
#   -N: next track

USER_ID=$1
# Pop the user ID off so the flags work correctly
shift

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/get_token.sh"
source "$PROJECT_ROOT/lib/requests.sh"

token=$(get_token $USER_ID)

is_silent=0

while getopts ":scPRBN" opt; do
    case "$opt" in
        's')
            is_silent=1
            ;;
        'c')
            currently_playing $token
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
    esac
done
