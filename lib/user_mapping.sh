#!/bin/bash

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

get_user_from_fingerprint() {
    local fingerprint="$1"
    local mapping_path="$PROJECT_ROOT/data/key_user_mappings"

    [[ -f "$mapping_path" ]] || return 1

    awk -F':' -v fp="$fingerprint" '$1 == fp {print $2; exit}' "$mapping_path"
}
