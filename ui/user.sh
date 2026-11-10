#!/bin/bash

USER_ID=$1
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"
source "$PROJECT_ROOT/lib/images.sh"
source "$PROJECT_ROOT/lib/components.sh"
source "$PROJECT_ROOT/lib/input.sh"
source "$PROJECT_ROOT/ui/topbar.sh"

# Load up the user's temporary directory
user_temp_dir="$PROJECT_ROOT/data/users/$USER_ID/temp"
if [[ ! -e $user_temp_dir ]]; then
    mkdir $user_temp_dir
fi

# Rendering
view_mode="default"
is_running=1
force_redraw=1

#Arguments: "mode"
print_commands() {
    if [[ $1 == "default" ]]; then
        print_highlight "(g) Navigate topbar" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
        echo -e "\n"
        print_highlight "(C) Logout & delete credentials" 0 "$CHARCOAL" $(( SCREEN_WIDTH / 8 * 6 )) "left"
    else
        echo -e "Unknown view mode\n\n"
    fi
}

while [[ "$is_running" -ne 0 ]]; do
    # Render results
    if [[ "$force_redraw" -eq 1 ]]; then
        clear
        draw_topbar 0
        print_commands $view_mode
    fi

    read -rsn1 key
    if [[ $key == $'g' ]]; then
        # Handle escape pressed
        exit 0
    fi

    case $key in
        'c')
            set_bottom_bar "Not an option. Did you mean 'C'? Press any key to continue"
            read -rsn1
            set_bottom_bar ""
            ;;
        'C')
            set_bottom_bar "Are you sure you would like to sign out? You will need to reauthenticate. [Y/N]"
            read -rsn1 choice
            case $choice in
                'y'|'Y')
                    # Clear
                    rm -rf "$PROJECT_ROOT/data/users/$USER_ID"
                    sed -i "/${USER_ID}/d" "$PROJECT_ROOT/data/key_user_mappings"
                    
                    clear
                    num_rows=$(tput lines)
                    for (( i=0; i < num_rows / 5 * 2; i++)); do echo -en "\n"; done;
                    print_highlight "You have been signed out." 1 "$VIOLET" "$SCREEN_WIDTH" "center"
                    print_highlight "Press any key to continue." 1 "$VIOLET" "$SCREEN_WIDTH" "center"
                    read -rsn1
                    clear
                    exit 1
                    ;;
                'n'|'N')
                    set_bottom_bar "Command aborted. Press any key to continue."
                    read -rsn1
                    set_bottom_bar ""
                    ;;
            esac
            ;;
    esac

done
