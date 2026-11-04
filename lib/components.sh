#!/bin/bash

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"

# Arguments: "jq song data" <indent_left> <max_width> highlighted? <index>?
print_song() {
    data=$1
    indent_left=$2
    max_width=$3

    name=$(echo "$data" | jq -r '.name')
    artists=$(echo "$data" | jq -r '[.artists[].name] | join(", ")')
    image_url=$(echo "$data" | jq -r '.album.images[-1].url')

    # if [[ $4 -eq 1 ]]; then
    #     printf "$WHITE_HIGHLIGHT"
    # fi
    
    local index=0
    while IFS= read -r pic_line; do
        printf "%s" "$pic_line" 

        if [[ $index -eq 1 ]]; then
            if (( $5 > 0 )); then
                printf " %2d %s" "$5" "$name"
            else
                printf "    %s" "$name"
            fi
        elif [[ $index -eq 2 ]]; then
            printf "    %s" "$artists"
        fi
        printf "\n"
        ((++index))
    done < <(indent_image "$image_url" 4 $2 1)

    while (( index < 4 )); do
        printf "\n"
        ((++index))
    done


    #
    # if [[ $4 -eq 1 ]]; then
    #     printf "$RESET"
    # fi
}

# Arguments: "jq songs data" <indent_left> <max_width> <highlighted_num>
print_songs() {
    songs_data=$1
    
    local index=0
    while IFS= read -r song; do
        if [[ $index -eq $4 ]]; then
            print_song "$song" "$2" "$3" 1 "$((index + 1))"
        else
            print_song "$song" "$2" "$3" 0 "$(( index + 1))"
        fi
        ((++index))
    done < <(jq -c '.[]' <<< "$songs_data")
}
