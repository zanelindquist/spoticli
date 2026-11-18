#!/bin/bash

# Arguments "user_id" [OPTIONS]
# OPTIONS:
#  -o: offset
#  -l: limit
#
#  -h: get history


USER_ID=$1
# Pop the user ID off so the flags work correctly
shift

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/get_token.sh"
source "$PROJECT_ROOT/lib/requests.sh"

# Load up the user's temporary directory
user_temp_dir="$PROJECT_ROOT/data/users/$USER_ID/temp"
if [[ ! -e $user_temp_dir ]]; then
    mkdir $user_temp_dir
fi
raw_library="$user_temp_dir/raw_library"


token=$(get_token $USER_ID)

offset=0
limit=10

is_history=0

while getopts ":o:l:h" opt; do
    case "$opt" in
        o)
            offset=$OPTARG
            ;;
        l)
            length=$OPTARG
            ;;
        h)
            is_history=1
            ;;
    esac
done


if [[ "$is_history" -eq 1 ]]; then
    get_recent_tracks "$token" "$limit"
else
    echo "Error: invalid syntax. Must include a command flag."
    exit 1
fi
