"""Minimal app skeleton. Replace with the fictional app for your challenge."""
from flask import Flask

app = Flask(__name__)

FLAG_PATH = "/srv/flag.txt"  # read at runtime, never hard-code the flag


@app.get("/")
def index():
    return "<h1>Portal Fiktif</h1><p>Ganti dengan aplikasi soal kamu.</p>"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
