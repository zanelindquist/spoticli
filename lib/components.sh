#!/bin/bash

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"

# Arguments: "top" "bottom" "image_url" <indent_left> <max_width> highlighted? <index>?
print_item() {
    top=$1
    bottom=$2
    image_url=$3
    indent_left=$4
    max_width=$5

    local index=0
    while IFS= read -r pic_line; do
        printf "%s" "$pic_line" 

        if [[ $index -eq 1 ]]; then
            if (( $5 > 0 )); then
                printf " %2d %s" "$7" "$top"
            else
                printf "    %s" "$top"
            fi
        elif [[ $index -eq 2 ]]; then
            printf "    %s" "${CHARCOAL}$bottom${RESET}"
        fi
        printf "\n"
        ((++index))
    done < <(indent_image "$image_url" 4 "$indent_left" 1)

    while (( index < 4 )); do
        printf "\n"
        ((++index))
    done
}

# Arguments: "jq songs data" <indent_left> <max_width> <highlighted_num> <start_index>?
print_songs() {
    data=$1
    start_index=$5 || 0

    echo -e "\n"
    
    local index=0
    while IFS= read -r song; do
        name=$(echo "$song" | jq -r '.name')
        artists=$(echo "$song" | jq -r '[.artists[].name] | join(", ")')
        image_url=$(echo "$song" | jq -r '.album.images[-1].url')

        if [[ $index -eq $4 ]]; then
            print_item "$name" "$artists" "$image_url" "$2" "$3" 1 "$(( start_index + index + 1))"
        else
            print_item "$name" "$artists" "$image_url" "$2" "$3" 0 "$(( start_index + index + 1))"
        fi
        ((++index))
    done < <(jq -c '.[]' <<< "$data")
}

# Arguments: "jq songs data" <indent_left> <max_width> <highlighted_num> <start_index>?
print_playlist() {
    data=$1
    start_index=$5 || 0

    echo -e "\n"
    
    local index=0
    while IFS= read -r song; do
        name=$(echo "$song" | jq -r '.name')
        artists=$(echo "$song" | jq -r '.owner.display_name')
        image_url=$(echo "$song" | jq -r '.images[-1].url')

        if [[ $index -eq $4 ]]; then
            print_item "$name" "$artists" "$image_url" "$2" "$3" 1 "$(( start_index + index + 1))"
        else
            print_item "$name" "$artists" "$image_url" "$2" "$3" 0 "$(( start_index + index + 1))"
        fi
        ((++index))
    done < <(jq -c '.[]' <<< "$data")
}
