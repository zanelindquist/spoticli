#!/bin/bash
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"

# Arguments "bottom_prefix" <max_number> <ptr>
get_number_dialogue() {
    declare -n num_ptr=$3
    prefix="$1"
    read -rs -n 1 digit_1
    set_bottom_bar "${prefix}${digit_1}"
    sleep 0.1

    # Make sure they are typing a num_ptr
    if [[ ! "$digit_1" =~ [0-9] || "$digit_1" -eq 0 ]]; then
        # If they aren't typing a num_ptr, continue
        set_bottom_bar "${prefix}: Input must be a number"
        read -r
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
            # If they aren't typing a num_ptr, continue
            continue
        else
            num_ptr=$(( digit_1 * 10 + digit_2))
        fi
    else
        num_ptr="$digit_1"
    fi

    set_bottom_bar "${prefix}${num_ptr}"
}
