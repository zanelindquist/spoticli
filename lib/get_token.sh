#!/bin/bash

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

# Arguments "user_id"
get_token() {
    if [[ "$1" == "" ]]; then
        echo "Error: get_token(): No user ID passed"
        exit 1
    fi

    token_path="$PROJECT_ROOT/data/users/$1/token"

    if [[ -z "$token_path" ]]; then
        echo "Error: get_token(): Could not locate user token directory"
        exit 1
    fi

    cat $token_path
}
