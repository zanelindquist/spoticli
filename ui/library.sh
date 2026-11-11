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
view_mode="library"
is_running=1
force_search_redraw=1

#Arguments: "mode"
print_commands() {
    if [[ $1 == "library" ]]; then
        print_highlight "(g) Navigate topbar (s) Search library (j) Scroll down (k) Scroll up" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
        print_highlight "(p) <number> Play playlist (v) <number> View playlist" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
    else
        echo -e "Unknown view mode\n\n"
    fi
}

while [[ "$is_running" -ne 0 ]]; do
    if [[ "$force_search_redraw" -eq 1 ]]; then
        clear
        draw_topbar 1
        print_commands "$view_mode"

        # Fetch library
        response=$(mktemp)
        "$PROJECT_ROOT/bin/spoticli" library $USER_ID -a -l 50 > "$response"

        items=$(jq -r '.items' < "$response")

# Arguments: "jq songs data" <indent_left> <max_width> <highlighted_num> <start_index>?
        print_playlist "$items" $(( SCREEN_WIDTH / 8 )) $(( SCREEN_WIDTH / 8 * 6 )) -1 0
 
    fi

    # Render results

    read -rsn1 key
    if [[ $key == $'g' ]]; then
        # Handle escape pressed
        exit 0
    fi

    case $key in
        's')

           ;;
        'j')

            ;;
        'k')

            ;;
        'p')

           ;;
        'a')

            ;;
    esac

done
