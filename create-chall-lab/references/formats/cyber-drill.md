# Cyber Drill

Two variants. Pick one per item and set `variant` in `exercise.yml`.

| Variant | What participants do | Template |
|---|---|---|
| `machine` | attack one vulnerable machine, HTB or THM style: foothold, privesc, objective | `templates/cyber-drill/machine/` |
| `blue` | investigate one fictional incident from logs and artifacts, SOC or IR style, and answer questions per phase | `templates/cyber-drill/blue/` |

Both need a fictional company from the narrative bank. For a repeat customer, check the
scenario-forge history so they get fresh content and a harder tier than last time.

## Variant `machine`

```
<slug>/
├── exercise.yml
├── Dockerfile           the machine
├── entrypoint.sh
├── app/                 the foothold service
├── docker-compose.yml   one service
├── flags/user.txt       readable after the foothold
├── flags/root.txt       readable only as root
├── solve.py             facilitator-only, prints both flags
├── brief.md             shipped: scenario framing only, zero spoilers
└── walkthrough.md       facilitator-only, step by step
```

- Attack chain: foothold, privesc, objective. Medium and hard can add one lateral hop inside the
  same container (a second local service on `127.0.0.1`).
- Two flags: user and root. Both follow the flag rules. `flags/` is copied into the image at
  the right owners and modes by the Dockerfile.
- `brief.md` says who the company is, what the team is asked to do, and the target address
  placeholder. No hints about the path.

Checks: required files, both flags valid and not in `app/` or `brief.md`, build, start, port
answers, `solve.py http://HOST:PORT` prints both flags, `root.txt` is owned by root and not
world-readable, compose safety.

## Variant `blue`

```
<slug>/
├── exercise.yml
├── timeline.json        the incident, event by event, with the exact log lines
├── noise.json           background traffic rules, so the incident is not the only thing in the logs
├── questions.json       questions per IR phase, with answers and where the evidence is
├── brief.md             shipped: the alert or report that starts the drill
├── build_pack.py        copied from the template, builds everything below
├── artifacts/           built: the log files, one folder per host
├── participant/         built: brief, questions without answers, artifacts.zip
├── ctfd/                built: one challenge.yml per question
└── facilitator/         built: answer key with evidence lines
```

### timeline.json

A list of events. Each event writes one exact line into one artifact file.

```json
{"t": "2026-11-05T09:14:03+07:00", "file": "web-01/access.log", "phase": "initial-access",
 "line": "10.20.4.17 - - [05/Nov/2026:09:14:03 +0700] \"POST /login HTTP/1.1\" 302 0",
 "note": "facilitator-only: first successful login after the spray"}
```

- Write the `line` in the real format of that log type (Apache, auth.log, Windows event JSON,
  Sysmon, firewall, DNS, EDR) with a timestamp that matches `t`.
- Keep one attacker story across hosts: same attacker IPs, same accounts, consistent times.
- Private or documentation IP ranges only.

### noise.json

Rules for benign background lines, so participants have to search. Each rule names a file, a
line template with `{t}`, `{ip}`, `{user}`, `{path}` slots, a count, and the values to pick
from. `build_pack.py` uses a fixed seed, so the output is the same every build.

### questions.json

```json
{"id": "q1", "phase": "Deteksi", "points": 100,
 "question": "IP mana yang pertama kali berhasil login ke web-01?",
 "answer": "10.20.4.17", "accept": ["10.20.4.17"],
 "evidence": {"file": "web-01/access.log", "contains": "10.20.4.17 - - [05/Nov/2026:09:14:03"}}
```

- Phases follow the IR flow: Deteksi, Analisis, Kontainmen, Eradikasi, Pemulihan. At least one
  question per phase the drill covers.
- Every answer must be provable from the artifacts. `evidence.contains` must appear in
  `evidence.file`. If the answer is a judgement (for example an ATT&CK id), set
  `"judgement": true` and keep `evidence` pointing at the lines that justify it.

Checks: `build_pack.py` runs, every evidence string is found, every non-judgement answer is in
the artifacts, every phase has a question, all IPs are private or documentation ranges, answers
do not appear in `participant/questions.md` or `brief.md`, and `ctfd/` has one challenge per
question.
