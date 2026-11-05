#!/usr/bin/env python3
"""Template solver buat soal file. Pakai: python3 solve.py dist/

Cuma baca isi dist/, persis yang didapat peserta. cek-soal.sh jalanin ini di folder kosong
yang cuma ada solve.py dan dist/, jadi solver yang ngintip flag.txt pasti gagal.
"""
import pathlib
import re
import sys

FLAG_RE = re.compile(r"[A-Za-z0-9_]+\{[^}]+\}")


def main():
    if len(sys.argv) != 2:
        print("usage: python3 solve.py dist/")
        sys.exit(2)
    dist = pathlib.Path(sys.argv[1])

    print("[*] langkah 1: baca file soal")
    data = (dist / "output.txt").read_text()
    # GANTI_INI: langkah solve soal ini, sama urutannya dengan writeup.md
    key = bytes.fromhex(re.search(r"key = (\w+)", data).group(1))
    ct = bytes.fromhex(re.search(r"ct = (\w+)", data).group(1))
    plain = bytes(a ^ b for a, b in zip(ct, key)).decode(errors="replace")

    m = FLAG_RE.search(plain)
    if not m:
        print("[-] flag nggak ketemu")
        sys.exit(1)
    print("[+] flag:", m.group(0))


if __name__ == "__main__":
    main()
