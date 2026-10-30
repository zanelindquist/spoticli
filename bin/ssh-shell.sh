#!/bin/bash
set -euo pipefail

# Source functions
source ./lib/user_mapping.sh
source ./lib/fingerprint.sh

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

# Reject client-requested commands for now.
# We'll implement the Spoticli command interface separately.
if [[ -n "${SSH_ORIGINAL_COMMAND:-}" ]]; then
    echo "Remote commands are not supported."
    exit 1
fi

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

# Get user's identity
fingerprint_user fingerprint

if [[ "$is_verbose" == "true" ]]; then
	echo "User fingerprint: $fingerprint"
fi

# Determine if the user has already authorized and has a token
# Get user's id from their fingerprint
user_id=$(get_user_from_fingerprint $fingerprint)

if [[ "$is_verbose" == "true" ]]; then
    echo "User id: $user_id"
fi

if [[ $user_id != "" ]]; then
	# Enter shell with the user's id
    
    # Check for reauth
    if "$PROJECT_ROOT/bin/spoticli" reauth $user_id; then
        status=0
    else
        status=$?
    fi

    if [[ $status -eq 1 ]]; then
        echo "Error: Fatal error caused program to quit"
        exit 1
    # This means reauth failed because the refresh token expired
    elif [[ $status -eq 2 ]]; then
        echo -e "\e[33mSpotify authorization expired. Redirecting to login...\e[0m"
        # Delete the key mapping from the public key to users, because the user session should be regenerated
        sed -i "/$fingerprint/d" "$PROJECT_ROOT/data/key_user_mappings"
        # Remove user token data
        rm -rf "$PROJECT_ROOT/data/users/$user_id"

	    "$PROJECT_ROOT/bin/spoticli" login $fingerprint

	    "$PROJECT_ROOT/ui/spoticli.sh" $user_id
    else
	    "$PROJECT_ROOT/ui/spoticli.sh" $user_id
    fi
else
	"$PROJECT_ROOT/bin/spoticli" login $fingerprint

	"$PROJECT_ROOT/ui/spoticli.sh" $user_id
fi
