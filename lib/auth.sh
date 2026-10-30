#!/bin/bash

# SpotiCLI authentication helpers

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
SESSION_DIR="$PROJECT_ROOT/data/sessions"

source "$PROJECT_ROOT/config/local.bash.env"
source "$PROJECT_ROOT/lib/fingerprint.sh"

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

    session_id=$1

    curl -Xsr GET "https://accounts.spotify.com/api/token" -H "content-type: application/json" -H "Authorization: Basic $SPOTIFY_CLIENT_ID:$SPOTIFY_CLIENT_SECRET" -d "{code: $2, redirect_uri: $redirect_uri, grant_type: 'authorization_code'"
}

# Returns the user's id when they are authenticated, or nothing if it failed
auth_wait() {
    declare -n u_id=$2

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

                u_id=$(cat $user_id_path)

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

reauth() {
    # Check if the user exists
    users_path="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")/data/users"
    user_path="$users_path/$1"

    if [[ ! -d $user_path ]]; then
        echo "Error: User directory not found '$user_path'"
        return 1
    fi

    expires_at=$(cat "$user_path/token_expires_at")
    current_time=$(python3 -c "import time; print(int(time.time()));")

    if [[ -z $expires_at || $current_time -gt $expires_at ]]; then
        # Do reauth flow
        refresh_token=$(cat "$user_path/refresh_token")
        auth_base64=$(printf '%s:%s' "$SPOTIFY_CLIENT_ID" "$SPOTIFY_CLIENT_SECRET" | base64 -w 0)

        response_file=$(mktemp)

        status_code=$(curl -sS \
            -o "$response_file" \
            -w "%{http_code}" \
            "https://accounts.spotify.com/api/token" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -H "Authorization: Basic $auth_base64" \
            --data-urlencode "grant_type=refresh_token" \
            --data-urlencode "refresh_token=$refresh_token")

        body=$(cat "$response_file")
        rm -f "$response_file"

        error=$(jq -r '.error // empty' <<< "$body")

        if [[ "$error" == "invalid_grant" ]]; then
            return 2
        fi

        if [[ $status_code != "200" ]]; then
            echo "Error: Reauth request failed with status code of $status_code"
            return 1
        fi

        access_token=$(jq -r '.access_token' <<< "$body")
        expires_in=$(jq -r '.expires_in' <<< "$body")

        new_refresh_token=$(jq -r '.refresh_token // empty' <<< "$body")

        if [[ -z $access_token ]]; then
            echo "Error: Could not parse new access token"
            return 1
        fi

        echo $access_token > "$user_path/token"
        echo "$(current_time + expires_in)" > "$user_path/token_expires_at"

        return 0
    fi

    # Didn't need to reauth
    return 0
}

