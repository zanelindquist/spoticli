#!/bin/bash

# Source the file relative to the script's actual location
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"

RESET=$'\e[0m'

options=(
	"Search"
	"Library"
	"HOME"
	"History"
	"User"
)
selected_option=0;
SCREEN_WIDTH=$(tput cols)
COL_WIDTH=$(( $SCREEN_WIDTH / 5 ))


while true; do
	clear

	for ((i=0; i<${#options[@]}; i++)); do
        is_selected="false"
        if [[ $i -eq $selected_option ]]; then
            is_selected="true"
        fi
        print_highlight " ${options[i]} " $is_selected "${GREEN_BLACK}" $COL_WIDTH "center"
    done

	read -rsn1 key

	case "$key" in
		$'\x1b')
			# Arrow keys start with ESC
			read -rsn2 key

			case "$key" in
				'[D')
					((selected_option = (selected_option - 1 + ${#options[@]}) % ${#options[@]}))
					;;
				'[C')
					((selected_option = (selected_option + 1) % ${#options[@]}))
					;;
			esac
			;;
		"")
			echo "ENTER"
			;;
		q)
			exit 0
			;;
	esac
done
