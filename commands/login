#!/usr/bin/env bash

# Arguements: <user_fingerprint>

set -euo pipefail

PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

source "$PROJECT_ROOT/lib/auth.sh"

# Load local development configuration if available.
if [[ -f "$PROJECT_ROOT/config/local.bash.env" ]]; then
    source "$PROJECT_ROOT/config/local.bash.env"
fi

: "${SPOTIFY_CLIENT_ID:?Set SPOTIFY_CLIENT_ID in config/local.bash.env}"
: "${SPOTIFY_REDIRECT_URI:?Set SPOTIFY_REDIRECT_URI in config/local.bash.env}"

session_id=$(auth_create_session)
state=$(auth_get_state "$session_id")

encoded_redirect_uri=$(python3 -c 'import urllib.parse, os; print(urllib.parse.quote(os.environ["SPOTIFY_REDIRECT_URI"], safe=""))')

printf '\nSpotiCLI Spotify Login\n\n'
printf 'Open this URL in your browser:\n\n'

auth_url="https://accounts.spotify.com/authorize?client_id=${SPOTIFY_CLIENT_ID}&response_type=code&redirect_uri=${encoded_redirect_uri}&state=${session_id}&scope=user-read-private%20user-read-email"

printf '%s\n\n' $auth_url

# Wait for the auth flow to return a user_id
auth_wait $session_id user_id

if [[ user_id != "" ]]; then
    # Add a row to the user fingerprint mapping file now that we have both pieces
    
    echo "$1:$user_id" >> "$PROJECT_ROOT/data/key_user_mappings"

    printf '\nYou are now connected to Spotify.\n'
    printf 'User ID: %s' $user_id
else
    printf '\nLogin failed. Please try again.\n' >&2
    exit 1
fi
