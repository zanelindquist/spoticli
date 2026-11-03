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
