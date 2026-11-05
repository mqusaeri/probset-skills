"""Template service foothold cyber drill. Ganti dengan aplikasi fiktif soal kamu.

Satu kelemahan yang dimaksud di sini kasih akses shell atau command execution sebagai user ctf.
Template ini belum punya kelemahan.
"""
from flask import Flask

app = Flask(__name__)


@app.get("/")
def index():
    return "<h1>Portal Fiktif</h1><p>Ganti dengan service foothold soal kamu.</p>"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
