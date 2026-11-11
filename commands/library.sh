#!/bin/bash

# Arguments "user_id" [OPTIONS]
# OPTIONS:
#  -a: all

USER_ID=$1
# Pop the user ID off so the flags work correctly
shift

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/get_token.sh"
source "$PROJECT_ROOT/lib/requests.sh"

token=$(get_token $USER_ID)

is_silent=0

offset=0
limit=10

while getopts ":o:l:a" opt; do
    case "$opt" in
        'o')
            offset="$OPTARG"
            ;;
        'l')
            limit="$OPTARG"
            ;;
        'a')
            get_library_items "$token" "playlists" $offset $limit
           ;;
     esac
done
