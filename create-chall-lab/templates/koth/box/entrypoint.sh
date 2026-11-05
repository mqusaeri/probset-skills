#!/bin/sh
# Mulai dari nol tiap container start: king balik ke nobody.
set -e
echo nobody > /root/king.txt
chown root:root /root/king.txt
chmod 644 /root/king.txt
python3 /opt/king/king_reader.py &
# GANTI_INI kalau jalur privesc butuh proses root lain (contoh loop cron), jalanin di sini dengan &.
exec runuser -u ctf -- gunicorn -b 0.0.0.0:8080 -w 2 --access-logfile - --chdir /app main:app
