#!/bin/bash

url="https://api.spotify.com/v1"

currently_playing() {
    token=$1
    auth_header="Authorization: Bearer ${token}"
    curl -s "${url}/me/player/currently-playing" -H "$auth_header"
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

