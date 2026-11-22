#!/bin/bash
set -eo pipefail

# Source functions
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/lib/user_mapping.sh"
source "$PROJECT_ROOT/lib/fingerprint.sh"
source "$PROJECT_ROOT/lib/images.sh"

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

if [[ "$is_verbose" == "true" && "$APP_ENV" == "local" ]]; then
	echo "User fingerprint: $fingerprint"
fi

# Determine if the user has already authorized and has a token
# Get user's id from their fingerprint
user_id=$(get_user_from_fingerprint $fingerprint)

if [[ "$is_verbose" == "true" && "$APP_ENV" == "local" ]]; then
    echo "User id: $user_id"
fi

print_logo_center 40 1
if [[ "$is_verbose" != "true" ]]; then
    sleep 1
fi
clear

if [[ $user_id != "" ]]; then
    # Check for reauth
    reauth_status=$("$PROJECT_ROOT/bin/spoticli" reauth $user_id)

    if [[ $reauth_status -eq 1 ]]; then
        echo "Error: Fatal error caused program to quit"
        exit 1
    # This means reauth failed because the refresh token expired
    elif [[ $reauth_status -eq 2 ]]; then
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
    user_id=$("$PROJECT_ROOT/bin/spoticli" login $fingerprint)

    if [[ "$is_verbose" == "true" && "$APP_ENV" == "local" ]]; then
        printf 'User ID: %s' $user_id
        echo -e "\nPress any key to continue...."
        read -r
    fi

	"$PROJECT_ROOT/ui/spoticli.sh" "$user_id"
fi
