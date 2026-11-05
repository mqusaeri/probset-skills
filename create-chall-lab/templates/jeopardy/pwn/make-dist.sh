#!/usr/bin/env bash
# Salin binary yang dijalanin container ke dist/chall, biar yang dikasih ke peserta sama persis.
# Jalanin di arsitektur yang sama dengan server event (biasanya amd64).
set -e
cd "$(dirname "$0")"
docker compose build >/dev/null
id="$(docker create "$(docker compose config --images | head -1)")"
mkdir -p dist
docker cp "$id:/home/ctf/chall" dist/chall
docker rm "$id" >/dev/null
echo "dist/chall siap ($(uname -m))"
