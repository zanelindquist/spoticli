#!/bin/bash

USER_ID=$1
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/print_colors.sh"
source "$PROJECT_ROOT/lib/images.sh"

response=$(mktemp)

"$PROJECT_ROOT/bin/spoticli" streamstate $USER_ID -c > "$response"

name=$(jq -r '.item.name' < "$response")
artists=$(jq -r '[.item.artists[].name] | join(", ")' < $response)
progress_ms=$(jq -r '.progress_ms' < $response)
duration_ms=$(jq -r '.item.duration_ms' < $response)

image_url=$(jq -r '.item.album.images[-1].url' < $response)

echo -e "\n\n"
indent_image $image_url $(( SCREEN_WIDTH / 2 )) $(( SCREEN_WIDTH / 4 ))
echo;
print_highlight "$name" 1 "$VIOLET" $SCREEN_WIDTH "center"
print_highlight "$artists" 1 "$VIOLET" $SCREEN_WIDTH "center"


# cat $response

rm $response
