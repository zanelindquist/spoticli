#!/bin/bash

SCREEN_WIDTH=$(tput cols)

# Arguments: "url" <width> <indent>
indent_image() {
    local padding=$3
    ascii-image-converter -C "$1" -W "$2" --threshold 0 |
    while IFS= read -r line; do
        line=${line##*$'\r'}
        printf "%*s%s\n" "$padding" "" "$line"
    done
}

# Arguments: <number> "line_ending"? "color
print_bars() {
    printf -- '-%.0s' $(seq 1 "$1")

    echo -en "$2"
}
