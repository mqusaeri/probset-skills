# Core rules, every format

Read this before writing code or content. The format guides add to these rules and never relax
them.

## exercise.yml

Every item folder starts with `exercise.yml`, copied from `templates/exercise.yml`. `cek-soal.sh`
reads it to pick the right checks. One `key: value` per line, no nesting.

| Key | Values | Notes |
|---|---|---|
| `format` | `jeopardy`, `attack-defense`, `koth`, `cyber-drill`, `ttx` | required |
| `category` | `web`, `pwn`, `reverse`, `crypto`, `forensics`, `osint`, `misc` | Jeopardy only |
| `delivery` | `service`, `files` | Jeopardy only. Web and pwn are `service`. Reverse, crypto and forensics are `files`. OSINT and misc can be either |
| `variant` | `machine`, `blue` | cyber drill only |
| `mode` | `workshop`, `probset` | default `workshop` |
| `difficulty` | `easy`, `medium`, `hard` | `hard` is probset only |
| `points` | number | must fit the table below |
| `flag_prefix` | `flag` by default | probset can use the client's prefix, for example `FLAG` |
| `port` | container port | service-based items only |
| `author` | text | |
| `narrative` | fictional organisation | from the scenario-forge narrative bank when available |
| `source` | one line | CVE, article, research, incident pattern, or own idea |

## Difficulty and points

| Difficulty | Steps on the intended path | Workshop points | Probset points |
|---|---|---|---|
| easy | about 2 | 100 | 50 to 100 |
| medium | 3 to 4 | 200 | 150 to 250 |
| hard | 5 or more, or one deep step | not allowed | 300 to 500 |

Points follow solve effort, never category. A/D, KOTH and TTX score live, so their `points`
field is the weight the facilitator gives the item, using the same ranges.

## Fictional names and addresses

- Organisations, products, people, domains: invented. Use `.lab`, `.test`, or `.example`
  domains.
- IP addresses in logs, stories, and configs: private ranges (`10.0.0.0/8`, `172.16.0.0/12`,
  `192.168.0.0/16`) or documentation ranges (`192.0.2.0/24`, `198.51.100.0/24`,
  `203.0.113.0/24`). `cek-soal.sh` flags anything else it finds.
- Never copy a real victim's name, a real leak, or real personal data, even from a news source.

## Flags

- One flag per item unless the format guide says otherwise (KOTH has none, cyber drill machine
  has two, A/D flags come from the checker, blue drill and TTX use answers).
- Generate it, never type it:

  ```sh
  python3 -c "import secrets; print('flag{' + secrets.token_hex(12) + '}')" > flag.txt
  ```

  Probset mode: swap `flag` for the client's `flag_prefix`.
- The flag string appears only in its flag file and in the platform metadata
  (`challenge.yml`). Never in source, templates, seed data, briefs, or comments.

## Containers (service-based items)

- One `Dockerfile` in the item root (or the folder the format guide names) and one service in
  `docker-compose.yml`.
- Official, pinned, multi-arch base images, for example `python:3.12-slim`, `node:22-alpine`,
  `php:8.3-apache`, `golang:1.23-alpine` plus `alpine:3.20`, `debian:12-slim`. Never `latest`.
- Pin library versions. Bind `0.0.0.0` on the port in `exercise.yml`. Start in under 10 seconds.
  Image under about 300 MB.
- No `privileged`, `cap_add`, `network_mode: host`, `docker.sock`, or bind mounts. Named volumes
  are fine where the format needs state (A/D).
- No outbound network calls at runtime. Everything is in the image.
- Run as a non-root user unless the format needs root (KOTH king reader, drill privesc target).

## Logging

Service-based items log one line per request to stdout: time, method or action, path or
command, status. After the event the facilitator hands these logs back for review.

## Participant vs facilitator files

| Ships to participants | Stays with the facilitator |
|---|---|
| service address, `dist/` files, `brief.md`, `participant/` | `writeup.md`, `walkthrough.md`, `solve.py`, `exploit.py`, `checker/`, `scorer.py`, answer keys, `facilitator/` |

`cek-soal.sh` scans the participant side for flags and answers.

## No unintended solves

- Debug mode off, no stack traces, no directory listing, no source maps, no backups, no `.git`.
- No default credentials apart from the ones the intended path uses.
- The flag is not in an HTML comment, a JS bundle, an error message, a header, or `strings` of
  a shipped file (unless reading it that way is the lesson).
- Fuzzing the obvious inputs should not reach a second, easier path.
