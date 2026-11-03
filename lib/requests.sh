#!/bin/bash

url="https://api.spotify.com/v1"

# ===== PLAYBACK CONTROL ======

currently_playing() {
    token=$1
    auth_header="Authorization: Bearer ${token}"
    response=$(curl -s "${url}/me/player/currently-playing" -H "$auth_header")

    echo "$response"
}
play_music(){
    token=$1
    auth_header="Authorization: Bearer ${token}"

    status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${url}/me/player/play" -H "$auth_header")

    echo "$status"
}
pause_music(){
    token=$1
    auth_header="Authorization: Bearer ${token}"

    status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${url}/me/player/pause" -H "$auth_header")

    echo "$status"
}
next_track(){
    token=$1
    auth_header="Authorization: Bearer ${token}"

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${url}/me/player/next" -H "$auth_header")

    echo "$status"
}
previous_track(){
    token=$1
    auth_header="Authorization: Bearer ${token}"

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${url}/me/player/previous" -H "$auth_header")

    echo "$status"
}

