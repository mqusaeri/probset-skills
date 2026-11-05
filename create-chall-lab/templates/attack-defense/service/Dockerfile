# Template servis A/D: Flask + gunicorn, data di /data (named volume) biar flag tahan restart.
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ .
RUN useradd -r -u 10001 svc && mkdir -p /data && chown svc /data
USER svc
EXPOSE 8080
CMD ["gunicorn", "-b", "0.0.0.0:8080", "-w", "2", "--access-logfile", "-", "main:app"]
