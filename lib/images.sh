#!/bin/bash

SCREEN_WIDTH=$(tput cols)
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

image_cache_path="$PROJECT_ROOT/data/cache/images"
if [[ ! -e $image_cache_path ]]; then
    mkdir -p $image_cache_path
fi



# Arguments: "url" <width> <indent> frame?
indent_image() {
    local padding=$3
    if [[ $4 -eq 1 ]]; then
        printf "%*s" "$padding" ""
        printf "┌"
        print_bars "$2" ""
        printf "┐\n"
    fi

    id="${1##*/}"
    # echo "$id"

    ascii-image-converter -C "$1" -W "$2" --threshold 0 |
    while IFS= read -r line; do
        line=${line##*$'\r'}
        string="%*s%s\n"
        if [[ $4 -eq 1 ]]; then
            string="%*s|%s|\n"
        fi
        printf $string "$padding" "" "$line"
    done
    if [[ $4 -eq 1 ]]; then
        printf "%*s" "$padding" ""
        printf "└"
        print_bars "$2" ""
        printf "┘\n"
    fi

}

# Arguments: <number> "line_ending"? "color
print_bars() {
    printf -- '-%.0s' $(seq 1 "$1")

    echo -en "$2"
}
