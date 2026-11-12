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
force_redraw=1

print_middle_screen "$GREEN" "Loading library..."

# Fetch library
library=$(mktemp)
"$PROJECT_ROOT/bin/spoticli" library $USER_ID -r -C -l 50 > "$library"
library_length=$(jq -r 'length' "$library")
page=0
page_length=7
total_pages=$(( library_length / page_length ))
if (( library_length % page_length != 0 )); then
    ((++total_pages))
fi

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
    if [[ "$force_redraw" -eq 1 ]]; then
        clear
        draw_topbar 1
        print_commands "$view_mode"

        display=$(jq -c ".[$((page * page_length)):$((page * page_length + page_length - 1))]" "$library")

        echo -e "\n"
        print_highlight "Page $(( page + 1 )) / $total_pages" 1 "$CHARCOAL" $SCREEN_WIDTH "center"
        # Display library based on pagination
        print_playlist "$display" $(( SCREEN_WIDTH / 8 )) $(( SCREEN_WIDTH / 8 * 6 )) -1 $(( page * page_length )) 

        force_redraw=0
    fi

    # Render results

    read -rsn1 key
    if [[ $key == $'g' ]]; then
        # Handle escape pressed
        is_running=0
    fi

    case $key in
        's')
            # Arguments "bottom_prefix" <max_number> <ptr>
            get_text_dialogue "search library: " query

            if [[ "$query" != "" ]]; then
                echo "$query"
            fi
           ;;
        # Pagination & movement
        'n'|'j'|'l')
            page=$(( ( page + 1 ) % total_pages ))
            force_redraw=1
            ;;
        'b'|'k'|'h')
            page=$(( ( page - 1 + total_pages ) % total_pages ))
            force_redraw=1
            ;;
        'p')

           ;;
    esac

done

rm "$library"
exit 0
