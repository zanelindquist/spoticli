#!/bin/bash

# Arguments "user_id" [OPTIONS]
# OPTIONS:
#  -o: offset
#  -l: limit
#
#  -a: all
#  -r: recent compilation
#    -C: Use cache for recency ordering

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
use_cache=0

while getopts ":o:l:arC" opt; do
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
        'C')
            use_cache=1
           ;;
     esac
done

# Do commands when we have enumerated flags already
if [[ "$is_all" -eq 1 ]]; then
    # get_recent_tracks "$token" 40
    get_library_items "$token" "playlists" $offset $limit
elif [[ "$is_recents" -eq 1 ]]; then
    cache="$user_temp_dir/library_cache"
    if [[ ! -f "$cache" ]]; then
        echo "" > "$cache"
    fi

    library=$(mktemp)
    if [[ "$use_cache" -eq 1 ]]; then
        recents=$(mktemp)
        # Get the context URIs 
        get_recent_tracks "$token" 50 | jq -r ".items | unique_by(.context.uri) | map(select(.context != null))" > "$recents"
        # Get the items from the library
        get_all_library_items "$token" "playlists" > "$library"

        # Find items that are in both
        both=$(jq -cn --slurpfile rec "$recents" --slurpfile lib "$library" '$lib[0] | map(select(.uri | IN($rec[0][].context.uri)))')
        rm "$recents"

        # Remove the ids from the cache, if present
        # Save unique items to cache
        # Use Move to Front heuristic for cache
        echo "$both" | jq -r '.[].uri' | while IFS= read -r unique_uri; do
           sed -i "/|^${unique_uri}|/d" "$cache"
           sed -i "1i\\${unique_uri}" "$cache"
        done

        # Now read the cache file and move those items to the front
        cached_uris=$(jq -R -s 'split("\n") | map(select(length > 0))' "$cache")
        # Sort recent tracks to the top
        sorted=$(jq -c --argjson order "$cached_uris" '
            ($order | to_entries | map({key: .value, value: .key}) | from_entries) as $pos
            | sort_by($pos[.uri] // ($order | length))
        ' "$library")

        echo "$sorted" > "$library"
    else
        get_library_items "$token" "playlists" $offset $limit | jq -c '.items' > "$library"
    fi

    # Now, return the library

    lib_string=$(cat "$library")
    rm "$library"
    echo "$lib_string"
fi
