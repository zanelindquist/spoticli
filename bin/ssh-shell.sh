#!/bin/bash

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
fingerprint_user user_id

echo "USER FINGERPRINT $user_id"

./spoticli login $user_id
