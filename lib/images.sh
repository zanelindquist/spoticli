#!/bin/bash

SCREEN_WIDTH=$(tput cols)
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/cache.sh"
source "$PROJECT_ROOT/lib/print_colors.sh"


# Arguments: "url" <width> <indent> frame?
indent_image() {
    local padding=$3
    if [[ $4 -eq 1 ]]; then
        printf "%*s" "$padding" ""
        printf "┌"
        print_bars "$2" ""
        printf "┐\n"
    fi

    # Get the image from the cache
    get_image_from_cache $1 $2 |
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

# Arguments: width print_text?
print_logo_center() {
    asset_path="$PROJECT_ROOT/assets/logo/logo-w${1}"
    
    num_rows=$(tput lines)
    num_cols=$(tput cols)
    width=$1

    # Print top offset
    clear
    for (( i=0; i < num_rows / 2 - width / 3 ; i++)); do echo -en "\n"; done;

    # Little offset of -6 since tput cols doesn't always center
    indent=$(( (cols - width) / 2  - 6 ))
    # See if the image is computed
    if [[ -s "$asset_path" ]]; then
        while IFS= read -r line; do
            printf "%*s%s\n" "$indent" "" "$line"
        done < <(cat "$asset_path")
    # If its not computed
    else
        ascii-image-converter -C "$PROJECT_ROOT/assets/logo/logo.png" -W "$width" --threshold 0 > "$asset_path"
        cat "$asset_path"
    fi

    if [[ ! -z "$2" && "$2" -eq 1 ]]; then
        # Arguments: "text" highlighted? "color" <width> "left,center,right"
        print_highlight "\tSpotiCLI \u00A9 2026" 1 "$GREEN" "$num_cols" "center"
        print_highlight "\tZane Lindquist" 1 "$GREEN" "$num_cols" "center"
        echo
        print_highlight "\t   https://github.com/zanelindquist/spoticli" 1 "$CHARCOAL" "$num_cols" "center"
    fi
}
