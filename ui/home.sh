#!/bin/bash

USER_ID=$1
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

response=$(mktemp)

"$PROJECT_ROOT/bin/spoticli" streamstate $USER_ID -c > "$response"

name=$(jq -r '.item.name' < "$response")

cat $response

rm $response

echo "You are listening to $name"
