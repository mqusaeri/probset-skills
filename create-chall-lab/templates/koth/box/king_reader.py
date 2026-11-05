#!/usr/bin/env python3
"""King reader: balikin baris pertama /root/king.txt di port 9999. Jalan sebagai root.

Scorer baca dari sini tiap interval. Tim nggak boleh matiin atau blok port ini (rules.md).
"""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

KING = "/root/king.txt"


class H(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            with open(KING, errors="replace") as f:
                name = f.readline().strip()[:64] or "nobody"
        except OSError:
            name = "nobody"
        body = (name + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 9999), H).serve_forever()
