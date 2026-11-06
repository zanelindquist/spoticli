#!/bin/bash

# LRU Caching

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
CACHE_SIZE=50

# Image will be stored in /images/w<width>/854abc3298cab.ansi
image_cache_path="$PROJECT_ROOT/data/cache/images"
# Cache manifests will be stored in /image_manifests/w<width>
image_cache_manifest_dir="$PROJECT_ROOT/data/cache/image_manifests"
if [[ ! -e $image_cache_path ]]; then
    mkdir -p $image_cache_path
fi
if [[ ! -e $image_cache_manifest_dir ]]; then
    mkdir -p "$PROJECT_ROOT/data/cache/image_manifests"
fi

# Arguments: "spotify_url" <width>
get_image_from_cache() {
    # Parse off the ID
    local id="${1##*/}"

    if [[ $1 == "" || $id == "null" ]]; then
        echo "Error: get_image_from_cache(): Spotify URL missing or null" >&2
        blank_image="$PROJECT_ROOT/data/cache/blank_image"
        echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==" | base64 -d > $blank_image
        echo $blank_image
    fi

    # Get the path to the image
    local image_dir="$image_cache_path/w${2}"
    local img_path="$image_dir/$id.ansi"
    local img_manifest="$image_cache_manifest_dir/w${2}"
    local image_ansi=$(printf "%-${2}s" "None")

    # Create paths to the files if they don't exist
    if [[ ! -f "$img_manifest" ]]; then
        touch "$img_manifest"
    fi
    if [[ ! -e "$image_dir" ]]; then
        mkdir -p "$image_dir"
    fi

    # Check if image is in cache
    if [[ -f "$img_path" ]]; then
        # If it's in the cache, then remove its id from the manifest since it will be prepended to the top later
        sed -i "/$id/d" "$img_manifest"

        # Load the ANSI
        image_ansi=$(cat "$img_path")
    else
        # If it's not in the cache, download the image, and remove last item if needed
        local line_count=$(wc -l < "$img_manifest")
        if (( line_count >= CACHE_SIZE )); then
            # Find the last index
            removal_id=$(tail -n 1 "$img_manifest")

            # Remove from end of manifest
            sed -i '$d' "$img_manifest"
            # Delete image ascii file
            rm "$image_cache_path/w${2}/$removal_id"
        fi

        image_ansi=$(ascii-image-converter -C "$1" -W "$2" --threshold 0)
        echo -E "$image_ansi" > "$img_path"
   fi

    # Prepend the index to the top
    sed -i "1i $id" "$img_manifest"

    # Return the ansi
    echo "$image_ansi"
}
