#!/bin/bash

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"

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
    printf -- '-%.0s' $(seq 1 "$SCREEN_WIDTH"); echo ""

    for ((i=0; i<${#options[@]}; i++)); do
        is_selected="false"
        if [[ $i -eq $1 ]]; then
            is_selected="true"
        fi
        print_highlight " ${options[i]} " $is_selected "${GREEN_BLACK}" $COL_WIDTH "center"
    done

    echo;

    printf -- '-%.0s' $(seq 1 "$SCREEN_WIDTH"); echo ""
}


