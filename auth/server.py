#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

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
        state = params.get("state", [None])[0]
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
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(
                b"<h1>No authorization code received</h1>"
            )
            return

        print(f"Authorization code received: {code}")
        print(f"State received: {state}")

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
