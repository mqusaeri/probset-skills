#!/usr/bin/env python3
"""Solver template. Usage: python3 solve.py http://HOST:PORT

Standard library only. Gets the flag from the running service, never from the local flag file.
Print one short line per step, matching the steps in writeup.md.
"""
import http.cookiejar
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

FLAG_RE = re.compile(r"flag\{[^}]+\}")

jar = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))


def request(base, path, data=None, headers=None, method=None):
    """Send a request and return (status, body). data dict is form-encoded."""
    url = base + path
    body = urllib.parse.urlencode(data).encode() if isinstance(data, dict) else data
    req = urllib.request.Request(url, data=body, headers=headers or {}, method=method)
    try:
        with opener.open(req, timeout=15) as resp:
            return resp.status, resp.read().decode(errors="replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode(errors="replace")


def main():
    if len(sys.argv) != 2:
        print("usage: python3 solve.py http://HOST:PORT")
        sys.exit(2)
    base = sys.argv[1].rstrip("/")

    print("[*] langkah 1: buka halaman utama")
    status, body = request(base, "/")

    # TODO: ganti dengan langkah solve soal ini, sama urutannya dengan writeup.md

    match = FLAG_RE.search(body)
    if not match:
        print("[-] flag nggak ketemu")
        sys.exit(1)
    print(f"[+] flag: {match.group(0)}")


if __name__ == "__main__":
    main()
