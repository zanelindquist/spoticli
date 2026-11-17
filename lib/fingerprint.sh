#!/bin/bash
# Responsible for identifying the user at entry via public SSH key in production or through name in development

# Load environment variables
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
source "$PROJECT_ROOT/config/prod.bash.env"

fingerprint_user() {
	declare -n output_var=$1
	if [[ $ENVIRONMENT == "development" ]]; then
		echo -e "\033[0;33mWARNING: In development mode. Public key fingerprinting not enabled.\033[0m"
		read -p "Enter user: " output_var
	elif [[ $ENVIRONMENT == "production" ]]; then
        output_var=$(cat "$SSH_USER_AUTH" | cut -d' ' -f3)
		if [[ "$output_var" != "" ]]; then
			# Do logic to find the user_id from the SSH Key fingerprint
			return "Successfully fingerprinted SSH user"
		else
			echo "Error: Public key fingerprinting failed"
			exit 1
		fi
	else
		echo "Error: Unexpected environment '$ENVIRONMENT'"
		exit 1
	fi
}
