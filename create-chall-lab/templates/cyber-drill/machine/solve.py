#!/usr/bin/env python3
"""Solver referensi cyber drill mesin. Khusus fasilitator.

Pakai: python3 solve.py http://HOST:PORT   cetak user flag dan root flag. Cuma standard library.
"""
import re
import sys
import urllib.request  # noqa: F401

FLAG_RE = re.compile(r"[A-Za-z0-9_]+\{[^}]+\}")


def main():
    if len(sys.argv) != 2:
        print("usage: python3 solve.py http://HOST:PORT")
        sys.exit(2)
    base = sys.argv[1].rstrip("/")
    print("[*] langkah 1: foothold")
    # GANTI_INI: foothold, baca /home/ctf/user.txt, privesc, baca /root/root.txt
    found = []
    for f in found:
        print("[+] flag:", f)
    sys.exit(0 if len(found) == 2 else 1)


if __name__ == "__main__":
    main()
