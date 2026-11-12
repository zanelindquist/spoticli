#!/bin/bash

# Arguments "user_id" [OPTIONS]
# OPTIONS:
#  -o: offset
#  -l: limit
#
#  -a: all
#  -r: recent compilation

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


token=$(get_token $USER_ID)

is_silent=0

offset=0
limit=10

is_all=0
is_recents=0

while getopts ":o:l:ar" opt; do
    case "$opt" in
        'o')
            offset="$OPTARG"
            ;;
        'l')
            limit="$OPTARG"
            ;;
        'r')
            is_recents=1
            ;;
        'a')
            is_all=1
           ;;
     esac
done

# Do commands when we have enumerated flags already
if [[ "$is_all" -eq 1 ]]; then
    # get_recent_tracks "$token" 40
    get_library_items "$token" "playlists" $offset $limit
elif [[ "$is_recents" -eq 1 ]]; then
    recents=$(mktemp)
    library=$(mktemp)
    # Get the context URIs 
    get_recent_tracks "$token" 50 | jq -r ".items | unique_by(.context.uri) | map(select(.context != null))" > "$recents"
    # Get the items from the library
    get_all_library_items "$token" "playlists" > "$library"
    # jq -r '.[0]' "$recents"
    # cat "$library" | head -n 65
    # Find items that are in both
    both=$(jq -n --slurpfile rec "$recents" --slurpfile lib "$library" '$lib[0] | map(select(.uri | IN($rec[0][].context.uri)))')

    rm "$recents"
    rm "$library"
    # Save unique items to cache
    #
    # Use Move to Front heuristic for cache
    echo "$both"
fi
