"""Template servis A/D: catatan pribadi per user. Ganti cerita dan fiturnya sesuai soal.

Checker nyimpen flag sebagai isi catatan, jadi nyuri flag artinya nyalahgunain fitur ini.
Kelemahan yang dimaksud ditaruh di sini, satu per nomor vuln. Template ini belum punya kelemahan.
"""
import os
import secrets
import sqlite3

from flask import Flask, abort, g, jsonify, request, session
from werkzeug.security import check_password_hash, generate_password_hash

DATA = os.environ.get("DATA_DIR", "/data")
DB = os.path.join(DATA, "app.db")

app = Flask(__name__)
key_path = os.path.join(DATA, "secret.key")
if not os.path.exists(key_path):
    with open(key_path, "w") as f:
        f.write(secrets.token_hex(32))
app.secret_key = open(key_path).read().strip()


def db():
    if "db" not in g:
        g.db = sqlite3.connect(DB)
        g.db.row_factory = sqlite3.Row
        g.db.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT UNIQUE, pw TEXT)")
        g.db.execute("CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY, owner INTEGER, title TEXT, body TEXT)")
    return g.db


@app.teardown_appcontext
def close_db(_):
    conn = g.pop("db", None)
    if conn is not None:
        conn.close()


def current_user():
    uid = session.get("uid")
    if uid is None:
        abort(401)
    return uid


@app.get("/")
def index():
    return "<h1>Catatan Fiktif</h1><p>API: /register, /login, /notes</p>"


@app.post("/register")
def register():
    d = request.get_json(force=True, silent=True) or {}
    u, p = d.get("username", ""), d.get("password", "")
    if not (3 <= len(u) <= 32) or len(p) < 6:
        return jsonify(error="username 3-32, password min 6"), 400
    try:
        db().execute("INSERT INTO users (username, pw) VALUES (?, ?)", (u, generate_password_hash(p)))
        db().commit()
    except sqlite3.IntegrityError:
        return jsonify(error="username sudah dipakai"), 409
    return jsonify(ok=True)


@app.post("/login")
def login():
    d = request.get_json(force=True, silent=True) or {}
    row = db().execute("SELECT id, pw FROM users WHERE username = ?", (d.get("username", ""),)).fetchone()
    if not row or not check_password_hash(row["pw"], d.get("password", "")):
        return jsonify(error="login gagal"), 403
    session["uid"] = row["id"]
    return jsonify(ok=True)


@app.post("/notes")
def create_note():
    uid = current_user()
    d = request.get_json(force=True, silent=True) or {}
    cur = db().execute("INSERT INTO notes (owner, title, body) VALUES (?, ?, ?)",
                       (uid, str(d.get("title", ""))[:100], str(d.get("body", ""))[:2000]))
    db().commit()
    return jsonify(id=cur.lastrowid)


@app.get("/notes")
def list_notes():
    uid = current_user()
    rows = db().execute("SELECT id, title FROM notes WHERE owner = ? ORDER BY id", (uid,)).fetchall()
    return jsonify(notes=[dict(r) for r in rows])


@app.get("/notes/<int:nid>")
def get_note(nid):
    uid = current_user()
    row = db().execute("SELECT id, title, body FROM notes WHERE id = ? AND owner = ?", (nid, uid)).fetchone()
    if not row:
        abort(404)
    return jsonify(dict(row))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
