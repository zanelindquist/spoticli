#!/bin/bash
# Arguments <user_id>

if [[ $1 == "" ]]; then
    echo "Error: User ID not provided"
    exit 1
fi

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

source "$PROJECT_ROOT/lib/auth.sh"

reauth "$1"
exit $?
