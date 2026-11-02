#!/bin/bash

USER_ID=$1
# Source the file relative to the script's actual location
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/ui/topbar.sh"


selected_option=2;
is_focused=1;


while true; do
	clear

    draw_topbar $selected_option

	read -rsn1 key

	case "$key" in
		$'\x1b')
			# Arrow keys start with ESC
			read -rsn2 -t 0.01 key

			case "$key" in
				'[D')
                    # Lock keys if this is not focused
                    if (( is_focused != 0 )); then
                        ((selected_option = (selected_option - 1 + ${#options[@]}) % ${#options[@]}))
                    fi
					;;
				'[C')
                    # Lock keys if this is not focused
                    if (( is_focused != 0 )); then
                        ((selected_option = (selected_option + 1) % ${#options[@]}))
                    fi
					;;
                "")
                    is_focused=1
                    ;;
			esac
			;;
		"")
            if [[ $selected_option == 2 ]]; then
                is_focused=0
                "$PROJECT_ROOT/ui/home.sh" $USER_ID
                read -r
            fi
			;;
		q)
			exit 0
			;;

	esac
done
