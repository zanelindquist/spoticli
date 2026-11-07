#!/bin/bash

# Arguments "user_id" [OPTIONS] "term"
# OPTIONS:
# -a: only artists
# -t: only tracks
# -q "term": query

USER_ID=$1
# Pop the user ID off so the flags work correctly
shift

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/get_token.sh"
source "$PROJECT_ROOT/lib/requests.sh"
source "$PROJECT_ROOT/lib/components.sh"

# Flags
type="track"
query=""

token=$(get_token $USER_ID)


while getopts ":atq:" opt; do
    case $opt in
        'a')
            type="artist"
            ;;
        't')
            type="track"
            ;;
        'q')
            query=$OPTARG
            ;;
    esac
done

search_term "$token" "$query" "$type"
