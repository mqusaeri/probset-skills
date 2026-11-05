#!/usr/bin/env python3
"""Template solver pwn. Pakai: python3 solve.py HOST:PORT

Cuma standard library (socket, struct). Ambil flag dari service yang jalan, bukan dari file lokal.
Cetak satu baris pendek per langkah, sama urutannya dengan writeup.md.
"""
import re
import socket
import struct  # noqa: F401  dipakai buat nyusun payload, contoh struct.pack("<Q", addr)
import sys

FLAG_RE = re.compile(rb"[A-Za-z0-9_]+\{[^}]+\}")


class Conn:
    def __init__(self, host, port):
        self.s = socket.create_connection((host, port), timeout=10)
        self.buf = b""

    def recvuntil(self, token):
        while token not in self.buf:
            chunk = self.s.recv(4096)
            if not chunk:
                break
            self.buf += chunk
        data, _, self.buf = self.buf.partition(token)
        return data + token

    def recvall(self):
        try:
            while True:
                chunk = self.s.recv(4096)
                if not chunk:
                    break
                self.buf += chunk
        except socket.timeout:
            pass
        data, self.buf = self.buf, b""
        return data

    def sendline(self, data):
        self.s.sendall(data + b"\n")


def main():
    if len(sys.argv) != 2 or ":" not in sys.argv[1]:
        print("usage: python3 solve.py HOST:PORT")
        sys.exit(2)
    host, port = sys.argv[1].rsplit(":", 1)
    c = Conn(host, int(port))

    print("[*] langkah 1: kenalan sama program")
    c.recvuntil(b"Nama: ")
    # GANTI_INI: payload sesuai kelemahan soal, sama urutannya dengan writeup.md
    c.sendline(b"tes")
    out = c.recvall()

    m = FLAG_RE.search(out)
    if not m:
        print("[-] flag nggak ketemu")
        sys.exit(1)
    print("[+] flag:", m.group(0).decode())


if __name__ == "__main__":
    main()
