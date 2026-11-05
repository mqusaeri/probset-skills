# Template box KOTH: service foothold (user ctf), satu jalur privesc ke root, king reader di port 9999.
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN useradd -m -u 10001 ctf
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ .
COPY king_reader.py /opt/king/king_reader.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh && chmod 700 /opt/king && chmod 600 /opt/king/king_reader.py

# GANTI_INI: satu jalur privesc yang dimaksud, contoh aturan sudo yang salah, skrip root yang
# bisa ditulis user ctf, atau helper SUID. Tulis jalurnya di writeup.md.

EXPOSE 8080 9999
# Container jalan sebagai root karena king reader butuh root. Service foothold turun ke user ctf.
ENTRYPOINT ["/entrypoint.sh"]
