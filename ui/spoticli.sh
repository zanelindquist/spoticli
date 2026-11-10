#!/bin/bash

USER_ID=$1
# Source the file relative to the script's actual location
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/ui/topbar.sh"

selected_option=1
hovered_option="$selected_option"
total_options=5
is_focused=0

handle_global_nav() {
    declare -n sel_opt=$1
    declare -n hov_opt=$2
    read -rs -n 1 post_exit_key

    # If user presses g again, then we want to be forgiving and just do all this again
    while [[ $post_exit_key == 'g' ]]; do
        read -rsn 1 post_exit_key
    done

    if [[ "$post_exit_key" =~ [1-$total_options] ]]; then
        sel_opt=$(( post_exit_key - 1 )) 
        sleep 1
        hov_opt=$sel_opt
    else
        case $post_exit_key in
            # Select navigation
            't')
                sel_opt=$(( (sel_opt + 1) % total_options ))
                hov_opt=$sel_opt
                ;;
            'T')
                sel_opt=$(( (sel_opt - 1 + total_options) % total_options ))
                hov_opt=$sel_opt
                ;;
            # Hover navigation (same as arrow keys)
           'h')
                # Lock keys if this is not focused
                hov_opt=$(( (hov_opt - 1 + total_options) % total_options ))
                sel_opt=-1
                ;;
            'l')
                # Lock keys if this is not focused
                hov_opt=$(( (hov_opt + 1) % total_options ))
                sel_opt=-1
                ;; 
            # Keys starting with escape
            $'\x1b')
                    # Arrow keys start with ESC
                    read -rsn2 -t 0.05 key

                    sel_opt=-1

                    case "$key" in
                        '[D')
                            # Lock keys if this is not focused
                            if (( is_focused != 0 )); then
                                hov_opt=$(( (hov_opt - 1 + total_options) % total_options ))
                            fi
                            ;;
                        '[C')
                            # Lock keys if this is not focused
                            if (( is_focused != 0 )); then
                                hov_opt=$(( (hov_opt + 1) % total_options ))
                            fi
                            ;;
                        "")
                            # Escape pressed
                            sel_opt=-1
                            is_focused=1
                            ;;
                    esac
                    ;;
                "")
                    # Enter key pressed
                    sel_opt=$hov_opt
                    ;;
                q)
                    clear
                    echo "Bye!!"
                    sleep 0.1
                    clear
                    exit 0
                    ;;
            *)
                hov_opt="$sel_opt"
                sel_opt=-1
        esac
    fi
}

home() {
    is_focused=0
    "$PROJECT_ROOT/ui/home.sh" $USER_ID
    # Allow terminal input in case the user exited at a weird time
    stty echo
    # When the program returns back, set the focus to the top bar
    is_focused=1
}


# Loop over keys
while true; do
    # Clear second line in return the cursor to its position
    clear
    draw_topbar $hovered_option

    # If a selected option is set, then we will run that command

    if [[ "$selected_option" -gt -1 ]]; then
        case $selected_option in
            0)
                "$PROJECT_ROOT/ui/search.sh" $USER_ID
                ;;
            1)
                echo "library"
                ;;
            2)
                home
                ;;
            3)
                echo "history"
                ;;
            4)
                "$PROJECT_ROOT/ui/user.sh" $USER_ID
                if [[ $? -eq 1 ]]; then
                    exit 0
                fi
                ;;
            *)
                echo "Error: unexpected selected option"
                selected_option=-1
                ;;
        esac
    fi

    # If we are here, control has been delegated to use to choose the next option
    handle_global_nav selected_option hovered_option
done
