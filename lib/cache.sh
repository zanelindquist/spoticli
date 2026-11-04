#!/bin/bash

# LRU Caching

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
CACHE_SIZE=100

image_cache_path="$PROJECT_ROOT/data/cache/images"
image_cache_manifest="$PROJECT_ROOT/data/cache/image_manifest"
if [[ ! -e $image_cache_path ]]; then
    mkdir -p $image_cache_path
fi
if [[ ! -f $image_cache_manifest ]]; then
    mkdir -p "$PROJECT_ROOT/data/cache"
    echo "" > "$PROJECT_ROOT/data/cache/image_manifest"
fi

# Arguments: <spotify_url>
get_image_from_cache() {
    # Parse off the ID
    local id="${1##*/}"

    if [[ $1 == "" ]]; then
        echo "Error: get_image_from_cache(): Spotify URL missing" >&2
    fi

    local img_path="$image_cache_path/$id"

    # Check if image is in cache
    if [[ -f "$img_path" ]]; then
        # If it's in the cache, then remove its id from the manifest
        sed -i "/$id/d" "$image_cache_manifest"
    else
        # If it's not in the cache, download the image, and remove last item if needed
        local line_count=$(wc -l < "$image_cache_manifest")
        if (( line_count >= CACHE_SIZE )); then
            # Find the last index
            removal_id=$(tail -n 1 "$image_cache_manifest")

            # Remove from end of manifest
            sed -i '$d' "$image_cache_manifest"
            # Delete image
            rm "$image_cache_path/$removal_id"
        fi

        # Download image
        wget -q -O "$image_cache_path/$id" "https://i.scdn.co/image/${id}"
   fi

    # Prepend the index to the top
    sed -i "1i $id" "$image_cache_manifest"

    # Return the image path
    echo "$img_path"
}
