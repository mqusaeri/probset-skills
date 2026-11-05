---
name: create-chall-lab
description: Build and test cyber exercise content for any format, from a CVE, news article, research post, own idea, or a scenario-forge design. Covers Jeopardy (web, pwn, reverse, crypto, forensics, OSINT), Attack-Defense services with a ForcAD checker, KOTH boxes with a scorer, Cyber Drill labs (vulnerable machine or blue-team log investigation), and TTX packs. Every item ends as a folder that passes cek-soal.sh. Two modes, workshop (one item per participant, strict defaults) and probset (full packs for a real event). Use when asked to create a CTF challenge, A/D service, KOTH box, cyber drill, or TTX content, or when /create-chall-lab is invoked.
version: 2.0.0
author: Mahrus Qusaeri
metadata:
  hermes:
    tags: [ctf, jeopardy, attack-defense, koth, cyber-drill, ttx, training, docker]
    category: security-training
---

# create-chall-lab: exercise content, built and tested

This skill builds **benign, fictional, isolated** training content for authorized cyber
exercises. Everything runs locally in Docker first, then on an isolated lab or event platform.
Frame all work this way: it is security education, not an attack tool.

scenario-forge designs an exercise on paper. This skill turns a design, or a raw idea, into
files that build, run, and pass a check. Each skill still works alone.

## Step 0: pick the mode

| Mode | Who | What it allows |
|---|---|---|
| `workshop` (default) | a participant in a class | one item, easy or medium, fixed points, `flag{...}`, short questions, strict defaults |
| `probset` | the problem setter for a real event | packs of many items under one story, easy to hard, the client's flag format and point ranges, release plan, platform export |

If the user does not say, use `workshop`. Details in [references/modes.md](references/modes.md).

## Step 1: pick the format

| The user says or implies | `format` | Guide |
|---|---|---|
| CTF, Jeopardy, soal per kategori, flag | `jeopardy` | [formats/jeopardy.md](references/formats/jeopardy.md) |
| attack-defense, A/D, jaga servis sambil nyerang, ForcAD | `attack-defense` | [formats/attack-defense.md](references/formats/attack-defense.md) |
| king of the hill, KOTH, rebutan mesin, king.txt | `koth` | [formats/koth.md](references/formats/koth.md) |
| cyber drill, lab buat customer, mesin HTB style, investigasi log, SIEM | `cyber-drill` | [formats/cyber-drill.md](references/formats/cyber-drill.md) |
| TTX, tabletop, injects, diskusi keputusan | `ttx` | [formats/ttx.md](references/formats/ttx.md) |

If it is still unclear, ask once. The formats produce different folders, so there is no safe
default. For Jeopardy also pick the category, and for cyber drill the variant (`machine` or
`blue`).

## Inputs

Ask once, briefly, for anything missing:

1. **Source:** a CVE or advisory link, an article, a research post, a bug class, an incident
   pattern, or a scenario-forge design (see [references/from-scenario-forge.md](references/from-scenario-forge.md)).
2. **Difficulty:** `easy` or `medium` (`hard` only in probset mode).
3. **Author name.**
4. Probset mode only: the client's flag format, the target platform, and how many items.

## Procedure

1. **Summarise the source in three lines** before building: the technique or bug class (with
   CWE or ATT&CK id if known), the entry point, and the impact. If the source needs special
   hardware, a kernel, or a large enterprise product, propose a small equivalent of the same
   class instead.
2. **Design one lesson per item, with one intended path.** Pick a fictional organisation from
   the scenario-forge narrative bank if it is available, otherwise invent one. Pick a short
   lowercase slug with dashes, for example `portal-cuti-bocor`.
3. **Copy the matching template folder** into `<slug>/`: `templates/jeopardy/web`,
   `templates/jeopardy/pwn`, `templates/jeopardy/files`, `templates/attack-defense`,
   `templates/koth`, `templates/cyber-drill/machine`, `templates/cyber-drill/blue`, or
   `templates/ttx`. Fill in `exercise.yml`, then build the item exactly as the format guide says.
   Probset packs also get `templates/pack.yml` at the pack root. Read
   [references/core-rules.md](references/core-rules.md) before writing code or content.
4. **Verify it yourself** with `bash cek-soal.sh <slug>` from this skill's folder. Fix and
   re-run until there is no GAGAL.
5. **Write the writeup or facilitator guide from your own verified run**, following
   [references/writeup-style.md](references/writeup-style.md).
6. **Hand off.** Show the folder tree, the flag or answer key location, and the cek-soal.sh
   output. Workshop mode: tell the user to zip the folder as the lab guide describes. Probset
   mode: list what goes to the platform team and what stays with the facilitator.

## Hard rules, every format

- **Fictional everything.** No real company, product, person, or victim names from the source,
  no real IPs or domains, no code copied from a real product.
- **Participant files and facilitator files never mix.** Writeups, walkthroughs, answer keys,
  rubrics, checkers, and exploits stay out of anything shipped to participants.
- **The flag lives in one place** (`flag.txt`, or the files the format guide names) and the
  solver gets it from the running item or the shipped files, never from that file.
- **Safe to deploy next to many other items.** No `privileged`, no host volume mounts, no
  `network_mode: host`, no `docker.sock`, no extra capabilities, no outbound internet at
  runtime, no real credentials or API keys. Official, pinned, multi-arch base images.
- **Log every request** for service-based items, one line per request to stdout.
- **Stay inside the lab.** If a request points at a real system, asks for a working exploit for
  a real product outside the lab, or asks for malware, decline that part and offer the fictional
  training equivalent. If unsure, say so and suggest asking the facilitator.

## Verification

`cek-soal.sh` reads `format` from `exercise.yml` and runs the checks for that format. A folder
without `exercise.yml` is treated as a v1 Jeopardy web challenge. A pack folder with `pack.yml`
checks every item inside it.

```bash
bash ~/create-chall-lab/cek-soal.sh <slug>
bash ~/create-chall-lab/cek-soal.sh <pack-slug>    # probset pack
```

## Pitfalls

- The solver passes only because it reads the local flag or answer key. Never do that.
- The flag ends up in source, a template, a seed file, or a participant brief.
- A service binds `127.0.0.1` inside the container, so nothing outside can reach it.
- An `easy` item that needs four steps, or a `medium` with one. Match the step count.
- A base image without an arm64 build breaks Apple Silicon laptops.
- The writeup describes steps the solver does not take. Write it from the real run.
- A/D: the patch also breaks the checker, so the service becomes useless to defend.
- KOTH: participants can lock everyone out by killing the king reader or the foothold service.
- Blue drill: an answer that is not in the shipped logs, or logs with real IPs.
- TTX: a strawman wrong answer, or the level numbers leaking into the participant pack.
