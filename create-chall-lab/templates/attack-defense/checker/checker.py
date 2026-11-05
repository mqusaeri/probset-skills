#!/usr/bin/env python3
"""Checker ForcAD / Hackerdom buat servis catatan. Khusus fasilitator.

  checker.py check HOST
  checker.py put   HOST FLAG_ID FLAG VULN    stdout: data buat get (jadi FLAG_ID berikutnya)
  checker.py get   HOST FLAG_ID FLAG VULN

Exit: 101 OK, 102 CORRUPT, 103 MUMBLE, 104 DOWN, 110 CHECKER_ERROR.
stdout waktu gagal tampil di scoreboard, jadi singkat. Detail debug ke stderr.
Cuma standard library. HOST boleh pakai port, contoh 10.10.1.2:8080.
"""
import http.cookiejar
import json
import secrets
import socket
import string
import sys
import urllib.error
import urllib.request

OK, CORRUPT, MUMBLE, DOWN, ERROR = 101, 102, 103, 104, 110
DEFAULT_PORT = 8080
TIMEOUT = 5


class Verdict(Exception):
    def __init__(self, code, public, private=""):
        super().__init__(public)
        self.code, self.public, self.private = code, public, private


def rnd(n=10):
    return "".join(secrets.choice(string.ascii_lowercase + string.digits) for _ in range(n))


class Client:
    def __init__(self, host):
        self.base = f"http://{host}" if ":" in host else f"http://{host}:{DEFAULT_PORT}"
        self.op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

    def call(self, method, path, data=None):
        body = json.dumps(data).encode() if data is not None else None
        req = urllib.request.Request(self.base + path, data=body, method=method,
                                     headers={"Content-Type": "application/json"})
        try:
            with self.op.open(req, timeout=TIMEOUT) as r:
                raw = r.read()
                status = r.status
        except urllib.error.HTTPError as e:
            raw, status = e.read(), e.code
        except (urllib.error.URLError, socket.timeout, ConnectionError, OSError) as e:
            raise Verdict(DOWN, "servis nggak bisa dihubungi", repr(e))
        try:
            return status, json.loads(raw or b"null")
        except ValueError:
            raise Verdict(MUMBLE, f"{method} {path} bukan JSON", raw[:200])

    def register_login(self, u, p):
        st, _ = self.call("POST", "/register", {"username": u, "password": p})
        if st != 200:
            raise Verdict(MUMBLE, "register gagal", f"status {st}")
        self.login(u, p, MUMBLE)

    def login(self, u, p, fail_code):
        st, _ = self.call("POST", "/login", {"username": u, "password": p})
        if st != 200:
            raise Verdict(fail_code, "login gagal", f"status {st}")


def do_check(host):
    c = Client(host)
    u, p = rnd(), rnd(12)
    c.register_login(u, p)
    title, body = rnd(8), rnd(24)
    st, d = c.call("POST", "/notes", {"title": title, "body": body})
    if st != 200 or not isinstance(d, dict) or "id" not in d:
        raise Verdict(MUMBLE, "bikin catatan gagal", f"status {st} {d}")
    st, d2 = c.call("GET", "/notes")
    if st != 200 or not any(n.get("id") == d["id"] for n in (d2 or {}).get("notes", [])):
        raise Verdict(MUMBLE, "daftar catatan nggak lengkap", f"status {st} {d2}")
    st, d3 = c.call("GET", f"/notes/{d['id']}")
    if st != 200 or (d3 or {}).get("body") != body:
        raise Verdict(MUMBLE, "isi catatan beda", f"status {st} {d3}")


def do_put(host, flag_id, flag, vuln):
    # VULN dipilih ForCAD di [1, places]. Kalau soal punya 2 vuln, simpan flag lewat fitur yang beda.
    c = Client(host)
    u, p = rnd(), rnd(12)
    c.register_login(u, p)
    st, d = c.call("POST", "/notes", {"title": rnd(8), "body": flag})
    if st != 200 or not isinstance(d, dict) or "id" not in d:
        raise Verdict(MUMBLE, "nyimpen flag gagal", f"status {st} {d}")
    print(json.dumps({"u": u, "p": p, "id": d["id"]}))


def do_get(host, flag_id, flag, vuln):
    try:
        info = json.loads(flag_id)
    except ValueError:
        raise Verdict(ERROR, "flag_id rusak", flag_id)
    c = Client(host)
    c.login(info["u"], info["p"], CORRUPT)
    st, d = c.call("GET", f"/notes/{info['id']}")
    if st == 404:
        raise Verdict(CORRUPT, "flag hilang")
    if st != 200 or (d or {}).get("body") != flag:
        raise Verdict(CORRUPT, "flag beda", f"status {st}")


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(ERROR)
    action, host = sys.argv[1], sys.argv[2]
    try:
        if action == "check":
            do_check(host)
        elif action == "put":
            do_put(host, *sys.argv[3:6])
        elif action == "get":
            do_get(host, *sys.argv[3:6])
        else:
            raise Verdict(ERROR, f"action {action} nggak dikenal")
    except Verdict as v:
        print(v.public)
        print(v.private, file=sys.stderr)
        sys.exit(v.code)
    except Exception as e:  # noqa: BLE001
        print("checker error")
        print(repr(e), file=sys.stderr)
        sys.exit(ERROR)
    sys.exit(OK)


if __name__ == "__main__":
    main()
