
#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
import subprocess
from pathlib import Path
import requests
import os
import base64
from dotenv import load_dotenv
import time
import uuid

HOST = "127.0.0.1"
PORT = 8080

class AuthHandler(BaseHTTPRequestHandler):

	def do_GET(self):
		parsed = urlparse(self.path)

		if parsed.path == "/":
			self.handle_home()
		elif parsed.path == "/callback":
			self.handle_callback(parsed)
		else:
			self.send_error(404, "Not Found")

	def handle_home(self):
		body = """
		<html>
			<head>
				<title>SpotiCLI</title>
			</head>
			<body>
				<h1>SpotiCLI</h1>
				<p>Authentication server is running.</p>
			</body>
		</html>
		"""

		self.send_response(200)
		self.send_header("Content-Type", "text/html")
		self.send_header("Content-Length", str(len(body.encode())))
		self.end_headers()

		self.wfile.write(body.encode())

	def handle_callback(self, parsed):
		params = parse_qs(parsed.query)

		code = params.get("code", [None])[0]
		session_id = params.get("state", [None])[0]
		error = params.get("error", [None])[0]

		print("\n--- Spotify Callback ---")

		if error:
			print(f"Spotify returned an error: {error}")
			self.send_response(400)
			self.send_header("Content-Type", "text/html")
			self.end_headers()
			self.wfile.write(
				b"<h1>Authentication failed</h1>"
			)
			return

		if not code:
			print("No authorization code received.")
			self.send_response(400)
			self.send_header("Content-Type", "text/tml")
			self.end_headers()
			self.wfile.write(
				b"<h1>No authorization code received</h1>"
			)
			return

		print(f"Authorization code received: {code}")
		print(f"State received: {session_id}")

		# Get .env information
		script_dir = Path(__file__).resolve().parent
		env_path = (script_dir / "../config/local.env").resolve()
		load_dotenv(dotenv_path=env_path, override=True)

		client_id = os.getenv("SPOTIFY_CLIENT_ID")
		client_secret = os.getenv("SPOTIFY_CLIENT_SECRET")
		redirect_uri = os.getenv("SPOTIFY_REDIRECT_URI")

		print(f"Loaded env file: {env_path.exists()}")
		print(f"Client ID present: {client_id}")
		print(f"Client secret present: {client_secret}")
		print(f"Redirect URI: {redirect_uri}")

		# Now exchange the code for a token

		auth_string = f"{os.getenv("SPOTIFY_CLIENT_ID")}:{os.getenv("SPOTIFY_CLIENT_SECRET")}"
		auth_bytes = auth_string.encode("utf-8")
		auth_base64 = base64.b64encode(auth_bytes).decode("utf-8")


		headers = {
				"Content-Type": "application/x-www-form-urlencoded",
				"Authorization": f"Basic {auth_base64}"
		}
		data = {
			"code": code,
			"redirect_uri": os.getenv("SPOTIFY_REDIRECT_URI"),
			"grant_type": "authorization_code"
		}

		response = requests.post("https://accounts.spotify.com/api/token", headers=headers, data=data)

		if response.status_code == 200:
			token_info = response.json()
			access_token = token_info["access_token"]
			refresh_token = token_info["refresh_token"]
			print(f"Success\nJSON Info: {token_info}")

			user_id = uuid.uuid4().hex

			user_session_path = script_dir / f"../data/sessions/{session_id}"
			user_data_path = script_dir / f"../data/users/{user_id}"
			# Create user's dir
			user_data_path.mkdir(parents=True, exist_ok=True)
			
			# Write token to file
			with open(user_data_path / "token", "w") as file:
				file.write(access_token)
				file.close()
				print("Token written to file")

			# Record refresh token
			with open(user_data_path / "refresh_token", "w") as file:
				file.write(refresh_token)
				file.close()
				print("Refresh token written to file")

			# Record token expiration
			with open(user_data_path / "token_expires_at", "w") as file:
				expires_at = int(time.time()) + token_info["expires_in"]
				file.write(str(expires_at))
				file.close()
			
			# Save the user_id to the session file
			with open(user_session_path / "user_id", "w") as file:
				file.write(user_id)
				file.close()
		
			# Finally update status path to indicate to the auth_wait function that we are complete and the user's files are ready
			with open(user_session_path / "status", "w") as file:
				file.write("authenticated")
				file.close()

		else:
			print(f"Error: {response.status_code}")
			print(response.json())

		self.send_response(200)
		self.send_header("Content-Type", "text/html")
		self.end_headers()

		self.wfile.write(
			b"""
			<html>
				<head>
					<title>SpotiCLI</title>
				</head>
				<body>
					<h1>Authentication successful!</h1>
					<p>You can return to your SSH session.</p>
				</body>
			</html>
			"""
		)

	def log_message(self, format, *args):
		print(f"[HTTP] {format % args}")


def main():
	server = HTTPServer((HOST, PORT), AuthHandler)

	print(f"SpotiCLI auth server listening on http://{HOST}:{PORT}")

	try:
		server.serve_forever()
	except KeyboardInterrupt:
		print("\nShutting down...")
	finally:
		server.server_close()


if __name__ == "__main__":
	main()
