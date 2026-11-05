# Template pwn: compile di build stage, jalan di bawah socat sebagai user biasa.
FROM debian:12-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY src/ .
# Proteksi binary nentuin cara solve. Tulis pilihan ini juga di writeup.md.
# Contoh tambahan sesuai pelajaran: -fno-stack-protector, -no-pie, -z execstack, -Wl,-z,norelro
RUN gcc -O0 -o chall chall.c

FROM debian:12-slim
RUN apt-get update && apt-get install -y --no-install-recommends socat && rm -rf /var/lib/apt/lists/* \
 && useradd -r -u 10001 -d /home/ctf ctf && mkdir -p /home/ctf
WORKDIR /home/ctf
COPY --from=build /src/chall /home/ctf/chall
COPY flag.txt /home/ctf/flag.txt
RUN chown root:ctf /home/ctf/chall /home/ctf/flag.txt && chmod 750 /home/ctf/chall && chmod 440 /home/ctf/flag.txt
USER ctf
EXPOSE 1337
# -d -d nyatet tiap koneksi ke log container.
CMD ["socat", "-d", "-d", "TCP-LISTEN:1337,reuseaddr,fork", "EXEC:/home/ctf/chall,stderr"]
