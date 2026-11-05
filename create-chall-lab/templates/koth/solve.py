#!/usr/bin/env python3
"""Solver referensi KOTH. Khusus fasilitator.

Pakai: python3 solve.py HOST:PORT TEAMNAME
Foothold, privesc ke root, lalu tulis TEAMNAME ke /root/king.txt. Cuma standard library.
"""
import sys
import urllib.parse
import urllib.request  # noqa: F401


def main():
    if len(sys.argv) != 3:
        print("usage: python3 solve.py HOST:PORT TEAMNAME")
        sys.exit(2)
    base, team = "http://" + sys.argv[1], sys.argv[2]
    print("[*] langkah 1: foothold")
    # GANTI_INI: foothold, privesc, lalu jalanin sebagai root: echo TEAMNAME > /root/king.txt
    print(f"[+] king sekarang: {team}")


if __name__ == "__main__":
    main()
