#!/bin/bash

USER_ID=$1
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"
source "$PROJECT_ROOT/lib/images.sh"
source "$PROJECT_ROOT/lib/components.sh"
source "$PROJECT_ROOT/ui/topbar.sh"

# Load up the user's temporary directory
user_temp_dir="$PROJECT_ROOT/data/users/$USER_ID/temp"
if [[ ! -e $user_temp_dir ]]; then
    mkdir $user_temp_dir
fi

# Rendering
view_mode="search"
is_running=1


#Arguments: "mode"
print_commands() {
    if [[ $1 == "search" ]]; then
        print_highlight "(g) Navigate topbar (s) Search query (j) Scroll down (k) Scroll up" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
        print_highlight "(p) <number> Play song (a) <number> Queue song (enter) Select search option" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
    else
        echo -e "Unknown view mode\n\n"
    fi
}

while [[ "$is_running" -ne 0 ]]; do
    clear
    draw_topbar 0
    print_commands $view_mode

    # Render results

    read -rsn1 key
    if [[ $key == $'g' ]]; then
        # Handle escape pressed
        exit 0
    fi
    case $key in
        's')
            query=""
            still_typing=1
            set_bottom_bar "query: "
            while [[ "$still_typing" -eq 1 ]]; do
                IFS= read -rsn1 next_letter
                # If they hit enter
                if [[ -z "$next_letter" ]]; then
                    still_typing=0
                    continue
                fi
                query+=$next_letter
                set_bottom_bar "query: $query"
            done
            response=$(mktemp)
            "$PROJECT_ROOT/bin/spoticli" search "$USER_ID" -q "$query" > "$response"
            tracks=$(jq -c ".tracks.items" < "$response")
            print_songs "$tracks" $(( SCREEN_WIDTH / 8 )) $(( SCREEN_WIDTH / 8 * 6 )) -1 0

            read -r
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
