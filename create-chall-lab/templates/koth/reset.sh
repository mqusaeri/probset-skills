#!/usr/bin/env bash
# Balikin box ke kondisi awal: build ulang dari nol, king balik ke nobody.
# Di event, fasilitator pakai cara reset platform-nya. Ini buat tes lokal dan cek-soal.sh.
set -e
cd "$(dirname "$0")"
docker compose down -v --remove-orphans >/dev/null 2>&1 || true
docker compose up -d --build >/dev/null
echo "box di-reset"
