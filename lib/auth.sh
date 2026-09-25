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

auth_wait() {
	local session_id="$1"
	local session_path="$SESSION_DIR/$session_id"

	echo "Waiting for Spotify authentication"
	while true; do
		local status
		status=$(cat "$session_path/status")

		case "$status" in
			authenticated)
				echo "✅ Spotify authentication success"
				return 0
				;;
			failed)
				echo "❌ Spotify authentication failed"
				return 0
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
