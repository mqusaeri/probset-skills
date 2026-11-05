# Template mesin cyber drill: foothold (user ctf), privesc, user flag dan root flag.
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN useradd -m -u 10001 ctf
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ .
COPY flags/user.txt /home/ctf/user.txt
COPY flags/root.txt /root/root.txt
COPY entrypoint.sh /entrypoint.sh
RUN chown ctf:ctf /home/ctf/user.txt && chmod 400 /home/ctf/user.txt \
 && chown root:root /root/root.txt && chmod 400 /root/root.txt && chmod 755 /entrypoint.sh

# GANTI_INI: satu jalur privesc yang dimaksud. Tulis jalurnya di walkthrough.md.

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
