# Jeopardy

Standalone challenges, solved in any order, one flag each. The category decides what the
challenge ships: a running service, files to download, or both.

## Category to delivery

| Category | `delivery` | Participants get | Template |
|---|---|---|---|
| web | service | a URL | `templates/jeopardy/web/` |
| pwn | service | `nc host port` plus the binary in `dist/` | `templates/jeopardy/pwn/` |
| reverse | files | a binary, APK, or script in `dist/` | `templates/jeopardy/files/` |
| crypto | files | the encryption script and its output in `dist/` | `templates/jeopardy/files/` |
| forensics | files | evidence in `dist/`: pcap, disk image, memory dump, logs, document | `templates/jeopardy/files/` |
| osint | service or files | a fictional trail: a small static site, or a starting clue in `dist/` | `web/` for a site, `files/` for a clue |
| misc | service or files | whatever the lesson needs | either |

## Layouts

Service (web, osint site):

```
<slug>/
├── exercise.yml
├── app/                 source of the fictional app or site
├── Dockerfile           builds the whole challenge
├── docker-compose.yml   local testing only, one service
├── flag.txt
├── solve.py             python3 solve.py http://HOST:PORT  prints the flag
├── writeup.md
└── challenge.yml
```

Service plus binary (pwn):

```
<slug>/
├── exercise.yml
├── src/                 chall.c and anything it needs
├── Dockerfile           compiles src/ and serves it on port 1337 with socat
├── docker-compose.yml
├── dist/chall           the same binary the container runs (cek-soal.sh compares hashes)
├── flag.txt
├── solve.py             python3 solve.py HOST:PORT  prints the flag
├── writeup.md
└── challenge.yml
```

Files (reverse, crypto, forensics, osint clue, misc):

```
<slug>/
├── exercise.yml
├── build/gen.py         facilitator-only, makes dist/ from flag.txt
├── dist/                exactly what participants download
├── flag.txt
├── solve.py             python3 solve.py dist/  prints the flag
├── writeup.md
└── challenge.yml
```

`cek-soal.sh` runs a files-category solver in an empty folder that holds only `solve.py` and a
copy of `dist/`, so a solver that peeks at `flag.txt` or `build/` fails.

## Per category

**web.** One fictional app with one intended flaw. Flask, Express, PHP or Go. App reads the flag
from a file at runtime. Port 8080. gunicorn with `--access-logfile -`, Express with
`morgan('combined')`, Apache logs by default. If the story needs an "internal service", run it
in the same container on `127.0.0.1` from a small `entrypoint.sh`. SQLite if it needs a database.

**pwn.** One small C program with one intended memory or logic flaw. Compile in a build stage,
run under `socat` as a non-root user, port 1337. State the compiler flags (canary, PIE, NX,
RELRO) in the Dockerfile and in the writeup, because they decide the solve. Ship the exact
binary in `dist/`. If the solve depends on a specific libc, ship it too. The solver uses only the
Python standard library (`socket`, `struct`), so it runs on any laptop.

**reverse.** One program whose logic hides the flag: a check routine, a simple VM, an
obfuscated script, an APK. `build/gen.py` produces `dist/` from `flag.txt`. The flag must not
show up in `strings dist/*`.

**crypto.** The encryption script and its output. The flaw is in how the primitive is used
(reused nonce, small exponent, weak key derivation, predictable random), never a broken library.
`build/gen.py` runs the script once with the flag and writes the output to `dist/`.

**forensics.** Evidence that tells one fictional incident. Generate it with `build/gen.py` (a pcap
written with `struct`, a log set, an image with metadata, a zip, a small disk image) so it can
be rebuilt. Keep files under about 50 MB. The flag hides where the lesson points, for
example in a reassembled stream or a deleted file, not in plain `strings`. If plain `strings` is
the lesson (easy), say so in the writeup and `cek-soal.sh` only warns.

**osint.** Fictional persona and organisation only. Never a real person, real account, or real
place tied to a real person. A site trail is a small static site in `app/`. A clue trail is a
starting artifact in `dist/` (photo with metadata, a profile export, a document). Every hop must
be inside the challenge.

## Flag

As in [core-rules.md](../core-rules.md). `solve.py` must get it from the running service or from
`dist/`, never from `flag.txt`.

## challenge.yml (ctfcli format)

```yaml
name: "Judul Soal"
author: "Nama Tim"
category: web            # same as exercise.yml
description: "Satu atau dua kalimat cerita fiktif. Jangan kasih tahu cara solve."
value: 100               # same as exercise.yml points
type: standard
flags:
  - "flag{...}"
files:                   # files delivery and pwn only
  - dist/namafile
connection_info: "http://[IP VPS]:[port]"   # service delivery; pwn: "nc [IP VPS] [port]"
state: visible
version: "0.1"
```

Leave the placeholders in `connection_info`. The facilitator fills them in at deploy time.

## solve.py

- Standard library only. Works on a fresh instance or a fresh copy of `dist/`, every time, in
  under 60 seconds.
- Prints one short line per step, matching the steps in `writeup.md`, then a line with the flag.
- Exits 0 on success and non-zero when it cannot find the flag.

## Checks run by cek-soal.sh

Required files, flag format and placement, `challenge.yml` matching `exercise.yml`, points in
range, pinned base image, compose safety, build, start, answer on the port, solver prints the
flag, request logging (web), pwn binary in `dist/` equals the one in the container, files solver
works from `dist/` alone, flag not in plain `strings` of `dist/`.
