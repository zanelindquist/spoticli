#!/bin/bash

SCREEN_WIDTH=$(tput cols)

# Straight text colors
RED=$'\e[38;5;196m'
ORANGE=$'\e[38;5;208m'
YELLOW=$'\e[38;5;226m'
GREEN=$'\e[38;5;46m'
BLUE=$'\e[38;5;21m'
INDIGO=$'\e[38;5;57m'
VIOLET=$'\e[38;5;165m'
CHARCOAL=$'\e[38;5;238m'
RESET=$'\e[0m'

# Contrast colors
GREEN_BLACK=$'\e[30;42m'
GREEN_WHITE=$'\e[37;42m'
WHITE_HIGHLIGHT=$'\e[97;107m'
CHARCOAL_BACKGROUND=$'\e[48;5;234m'


# Print colors

# Arguments: "text" highlighted? "color" <width> "left,center,right"
print_highlight() {
    local text_length=${#1}
    local width=${4:-$text_length}
    local center_padding=$(( (width - text_length) / 2 ))
    local one_side_padding=$(( width - text_length ))

    local text=$1

    # Set highlighting
    if [[ $2 -ne 0 ]]; then
        text="$3${1}${RESET}"
    fi

    if [[ $5 == "right" ]]; then
        printf "%${one_side_padding}s" ""
        echo -en $text
    elif [[ $5 == "left" ]]; then
        echo -en $text
        printf "%${one_side_padding}s" ""
    elif [[ $5 == "center" ]]; then
        printf "%${center_padding}s" ""
        echo -en $text
        printf "%${center_padding}s" ""
    else
        echo -en $text
    fi
}

# Arguments: "text"
set_bottom_bar() {
    local cols=$(tput cols)
    local lines=$(tput lines)

    # Hold position
    tput sc
    # Go to last line
    tput cup $((lines - 2)) 0

    if [[ "$1" == "" ]]; then
        # Remove bottom bar
        echo -e "\e[2K"
    else
        # Print bar
        printf "%b%-${cols}s%b" "$CHARCOAL_BACKGROUND" "$1" "$RESET"
    fi
    # Return to where cursor was
    tput rc
}


