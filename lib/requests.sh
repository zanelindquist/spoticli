#!/bin/bash

url="https://api.spotify.com/v1"

# ===== PLAYBACK CONTROL ======

# Arguments: "token"
currently_playing() {
    token=$1
    auth_header="Authorization: Bearer ${token}"
    response=$(curl -s "${url}/me/player/currently-playing" -H "$auth_header")

    echo "$response"
}
# Arguments: "token"
play_music(){
    token=$1
    auth_header="Authorization: Bearer ${token}"

    status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${url}/me/player/play" -H "$auth_header")

    echo "$status"
}
# Arguments: "token"
pause_music(){
    token=$1
    auth_header="Authorization: Bearer ${token}"

    status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${url}/me/player/pause" -H "$auth_header")

    echo "$status"
}
# Arguments: "token"
next_track(){
    token=$1
    auth_header="Authorization: Bearer ${token}"

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${url}/me/player/next" -H "$auth_header")

    echo "$status"
}
# Arguments: "token"
previous_track(){
    token=$1
    auth_header="Authorization: Bearer ${token}"

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${url}/me/player/previous" -H "$auth_header")

    echo "$status"
}
# Arguments: "token" is_schuffle?
set_shuffle(){
    token=$1
    auth_header="Authorization: Bearer ${token}"
    is_schuffle=$2
    state="true"
    if [[ $is_schuffle == 0 ]]; then
        state="false"
    fi

    status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${url}/me/player/shuffle?state=${state}" -H "$auth_header")

    echo "$status"
}
# Arguments: "token"
get_queue() {
    token=$1
    auth_header="Authorization: Bearer ${token}"
    response=$(curl -s "${url}/me/player/queue" -H "$auth_header")

    echo "$response"
}
# Arguments: "token" "track_uri"
queue_song() {
    token=$1
    auth_header="Authorization: Bearer ${token}"
    parsed_uri=$(echo "$2" | sed 's/:/%3A/g')
    response=$(curl -s -X POST "${url}/me/player/queue?uri=${parsed_uri}" -H "$auth_header")

    echo "$response"
}
# Arguments: "token" "track_uri"
set_playback_track() {
    token=$1
    auth_header="Authorization: Bearer ${token}"
    track_id=$(echo "$2" | awk -F: '{print $3}')
    
    # Spotify API bug prevents you from playing a song directly, so you need to workaround with the album
    album_uri=$(curl -s -X GET "${url}/tracks/${track_id}" -H "$auth_header" -H "Content-Type: application/json" | jq -r '.album.uri')
    # Play on currently playing device
    device_id=$(curl -s "${url}/me/player/devices" -H "$auth_header" | jq -r '.devices[] | select(.is_active) | .id')
    data=$( jq -n --arg a_uri "$album_uri" --arg t_uri "$2" '{context_uri: $a_uri, offset: {uri: $t_uri}}' )

    status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${url}/me/player/play?device_id=${device_id}" -H "$auth_header" -H "Content-Type: application/json" -d "$data")

    echo "$status"
}

# ===== Searching =====

# Arguments: "token" "term" "type"
search_term() {
    token=$1
    auth_header="Authorization: Bearer ${token}"
    #TODO imeplement types
    response=$(curl -sG "${url}/search" --data-urlencode "q=${2}" --data-urlencode "type=${3}" -H "$auth_header")

    echo "$response"
}
