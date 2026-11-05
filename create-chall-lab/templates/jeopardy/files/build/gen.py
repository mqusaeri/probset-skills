#!/usr/bin/env python3
"""Bikin isi dist/ dari flag.txt. Khusus fasilitator, nggak dikirim ke peserta.

Jalanin dari folder soal: python3 build/gen.py
Ganti isi make_dist() dengan cara soal kamu nyembunyiin flag:
  reverse   compile atau obfuscate program pengecek
  crypto    jalanin skrip enkripsi sekali, simpan output-nya
  forensics tulis pcap, log, image, atau zip yang nyimpen flag di tempat yang dimaksud
  osint     bikin artefak awal (foto dengan metadata, export profil) buat jejak fiktif
"""
import pathlib
import secrets

BASE = pathlib.Path(__file__).resolve().parent.parent
DIST = BASE / "dist"


def make_dist(flag: str):
    # GANTI_INI: contoh doang. XOR dengan key acak, key ikut dikirim. Ganti dengan pelajaran soal kamu.
    key = secrets.token_bytes(len(flag))
    cipher = bytes(a ^ b for a, b in zip(flag.encode(), key))
    (DIST / "output.txt").write_text(f"key = {key.hex()}\nct = {cipher.hex()}\n")


def main():
    flag = (BASE / "flag.txt").read_text().strip()
    DIST.mkdir(exist_ok=True)
    for f in DIST.iterdir():
        if f.is_file() and f.name != ".gitkeep":
            f.unlink()
    make_dist(flag)
    print("dist/ siap:", ", ".join(sorted(p.name for p in DIST.iterdir() if p.name != ".gitkeep")))


if __name__ == "__main__":
    main()
