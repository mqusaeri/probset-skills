# Template: Python + Flask + gunicorn. Swap the base image and CMD for other stacks.
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

# The flag lives only in flag.txt. Copy it to the place the intended flaw can reach.
COPY flag.txt /srv/flag.txt

RUN useradd -r -u 10001 ctf && chmod 444 /srv/flag.txt
USER ctf

EXPOSE 8080
# --access-logfile - prints one line per request to stdout, the facilitator exports it later.
CMD ["gunicorn", "-b", "0.0.0.0:8080", "-w", "2", "--access-logfile", "-", "main:app"]
