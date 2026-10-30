#!/bin/bash

# Debug tacks
is_verbose=false

while getopts "v" opt; do
	case "${opt}" in
		v)
			is_verbose=true
			;;
		*)
			;;
	esac
done

set -euo pipefail

# Reject client-requested commands for now.
# We'll implement the Spoticli command interface separately.
if [[ -n "${SSH_ORIGINAL_COMMAND:-}" ]]; then
    echo "Remote commands are not supported."
    exit 1
fi

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

# Get user's identity
source ./lib/fingerprint.sh
fingerprint_user fingerprint

if [[ "$is_verbose" == "true" ]]; then
	echo "User fingerprint $fingerprint"
fi

# Determine if the user has already authorized and has a token
# Get user's id from their fingerprint
source ./lib/user_mapping.sh
user_id=$(get_user_from_fingerprint $fingerprint)

echo "User id: $user_id"

if [[ $user_id != "" ]]; then
	# Enter shell with the user's id
	
	"$PROJECT_ROOT/ui/spoticli.sh" $user_id
else
	"$PROJECT_ROOT/bin/spoticli" login $fingerprint

	"$PROJECT_ROOT/ui/spoticli.sh" $user_id
fi
