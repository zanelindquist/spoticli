#!/bin/bash

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"
source "$PROJECT_ROOT/lib/images.sh"

SCREEN_WIDTH=$(tput cols)
COL_WIDTH=$(( $SCREEN_WIDTH / 5 ))

options=(
	"Search"
	"Library"
	"Home"
	"History"
	"User"
)

# Arguments <selected_option>
draw_topbar() {
    print_bars $SCREEN_WIDTH ""

    for ((i=0; i<${#options[@]}; i++)); do
        is_selected=0
        if [[ $i -eq $1 ]]; then
            is_selected=1
        fi
        print_highlight " ${options[i]} " $is_selected "${GREEN_BLACK}" $COL_WIDTH "center"
    done

    echo;

    print_bars $SCREEN_WIDTH ""
}


