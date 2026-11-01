#!/bin/bash

SCREEN_WIDTH=$(tput cols)

# Arguments: "url" <width> <indent>
indent_image() {
    local padding=$3
    echo -n " "
    ascii-image-converter -C "$1" -W "$2" |
    while IFS= read -r line; do
        line=${line##*$'\r'}
        printf "%*s%s\n" "$padding" "" "$line"
    done
}
