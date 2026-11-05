#!/bin/sh
set -e
# GANTI_INI kalau jalur privesc butuh proses root (contoh loop cron), jalanin di sini dengan &.
exec runuser -u ctf -- gunicorn -b 0.0.0.0:8080 -w 2 --access-logfile - --chdir /app main:app
