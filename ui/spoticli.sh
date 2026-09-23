#!/bin/bash

GREEN_BLACK='\e[30;42m'
RESET='\e[0m'

options=(
	"Search"
	"Library"
	"HOME"
	"History"
	"User"
)
selected_option=0;

while true; do
	clear

	for ((i=0; i<${#options[@]}; i++)); do
		if [[ $i -eq $selected_option ]]; then
			echo -en "${GREEN_BLACK}${options[$i]}${RESET} "
		else
			echo -n "${options[$i]} "
		fi
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
