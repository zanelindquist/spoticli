#!/bin/bash

# Arguments "user_id" [OPTIONS]
# OPTIONS:
#   -c: currently playing

USER_ID=$1
# Pop the user ID off so the flags work correctly
shift

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/get_token.sh"
source "$PROJECT_ROOT/lib/requests.sh"

token=$(get_token $USER_ID)

while getopts ":c" opt; do
    case "$opt" in
        'c')
            currently_playing $token
            ;;
        *)
            echo "Error: streamstate handling unknown flag"
    esac
done
