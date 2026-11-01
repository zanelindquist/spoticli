#!/bin/bash

url="https://api.spotify.com/v1"

currently_playing() {
    token=$1
    auth_header="Authorization: Bearer ${token}"
    curl -s "${url}/me/player/currently-playing" -H "$auth_header"
}
