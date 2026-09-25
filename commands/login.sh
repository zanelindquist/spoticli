session_id=$(auth_start)
auth_wait "$session_id"

if auth_success "$session_id"; then
	echo "Logged in!"
fi
