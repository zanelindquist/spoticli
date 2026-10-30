#!/bin/bash

# SpotiCLI authentication helpers

SESSION_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")/data/sessions"

# Create a new auth session

auth_create_session() {
	local session_id
	local session_path

	session_id=$(openssl rand -hex 16)
	session_path="$SESSION_DIR/$session_id"

	mkdir -p "$session_path"

	# Generate OAuth state
	openssl rand -hex 32 > "$session_path/state"

	echo $USER > "$session_path/user"

	echo "pending" > "$session_path/status"

	date "+%Y-%m-%d %H:%M:%S" > "$session_path/created_at"

	echo "$session_id"
}

# Params: <session_id>
auth_get_state() {
	cat "$SESSION_DIR/$1/state"
}

# Params: <session_id>
auth_get_status() {
	cat "$SESSION_DIR/$1/status"
}

# Params: <session_id> <state>
auth_set_state() {
    echo "$2" > "$SESSION_DIR/$1/state"
}

# Params: <session_id> <authorization_code>
auth_exchange_code() {
    source ../config/local.bash.env

    session_id=$1

    curl -Xsr GET "https://accounts.spotify.com/api/token" -H "content-type: application/json" -H "Authorization: Basic $SPOTIFY_CLIENT_ID:$SPOTIFY_CLIENT_SECRET" -d "{code: $2, redirect_uri: $redirect_uri, grant_type: 'authorization_code'"
}

# Returns the user's id when they are authenticated, or nothing if it failed
auth_wait() {
    declare -n user_id=$2

	local session_id="$1"
	local session_path="$SESSION_DIR/$session_id"

	echo "Waiting for Spotify authentication..."
	while true; do
		local status
		status=$(cat "$session_path/status")

		case "$status" in
			authenticated)
                # Now it says authenticated, find the user file, and read that
                
                # Check that the user_id file exists
                user_id_path="$session_path/user_id"
                if [[ -z $user_id_path ]]; then
                    echo "Error: Could not locate user_id file in session"
                    return 1
                fi

                user_id=$(cat $user_id_path)

				echo -e "\e[32m\nSpotify authentication success\e[0m"

                # Delete temporary session file
                rm -rf $session_path

				return 0
				;;
			failed)
				echo "Spotify authentication failed"
				return 1
				;;
			pending)
				sleep 1
				;;
			*)
				echo "Unkown authentication status: $status"
				return 1
				;;
		esac
	done

}
