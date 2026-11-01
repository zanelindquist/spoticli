#!/bin/bash

# Source the file relative to the script's actual location
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/ui/topbar.sh"


selected_option=0;
SCREEN_WIDTH=$(tput cols)
COL_WIDTH=$(( $SCREEN_WIDTH / 5 ))


while true; do
	clear

    draw_topbar $selected_option

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
