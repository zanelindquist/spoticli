#!/bin/bash
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"

# Arguments "bottom_prefix" <max_number> <ptr>
get_number_dialogue() {
    declare -n num_ptr=$3
    prefix="$1"
    set_bottom_bar "$prefix"
    read -rsn1 digit_1
    set_bottom_bar "${prefix}${digit_1}"
    sleep 0.1

    # Make sure they are typing a num_ptr
    if [[ ! "$digit_1" =~ [0-9] || "$digit_1" -eq 0 ]]; then
        # If they aren't typing a num_ptr, continue
        set_bottom_bar "${prefix}: Input must be a number. Press any key to continue."
        read -rsn1
        set_bottom_bar ""
        return -1
    fi
    # If the user could still be typing more digits.. wait for that digit
    num_ptr=0
    if (( digit_1 * 10 < $2 )); then
        set_bottom_bar "${prefix}${digit_1}        Enter to finish"
        read -rs -n 1 digit_2
        if [[ "$digit_2" == "" ]]; then
            num_ptr="$digit_1"
        elif [[ ! "$digit_2" =~ [0-9] ]]; then
            # If they aren't typing a num_ptr, exit
            set_bottom_bar ""
            return 0
        else
            num_ptr=$(( digit_1 * 10 + digit_2))
        fi
    else
        num_ptr="$digit_1"
    fi

    set_bottom_bar "${prefix}${num_ptr}"
}

# Arguments: "prefix" string<ptr>
get_text_dialogue() {
    declare -n text=$2
    still_typing=1
    user_canceled=0
    set_bottom_bar "$1"
    while [[ "$still_typing" -eq 1 && "$user_canceled" -ne 1 ]]; do
        IFS= read -rsn1 next_letter
        # If they hit enter
        if [[ -z "$next_letter" ]]; then
            still_typing=0
            set_bottom_bar ""
            continue
        fi
        # Handle escape key pressed
        if [[ "$next_letter" == $'\e' ]]; then
            set_bottom_bar ""
            # Set text to "" if they cancedled
            text=""
            user_canceled=1
            break
        fi
        # Handle delete key
        if [[ "$next_letter" == $'\x7f' || "$next_letter" == $'\x08' ]]; then
            text="${query%?}"
        else
            text+=$next_letter
        fi
        set_bottom_bar "${1}${text}"
    done
}

# Arguments: "error"
error_message() {
    set_bottom_bar "$1 Press any key to continue..."
    read -rsn1
    set_bottom_bar ""
}
