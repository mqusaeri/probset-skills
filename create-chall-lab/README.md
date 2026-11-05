# create-chall-lab

An agent skill that builds and tests cyber exercise content. It works with Hermes, OpenClaw,
Claude Code, Codex and OpenCode. Every item ends as a folder that passes `cek-soal.sh`.

| Format | What you get |
|---|---|
| Jeopardy | web, pwn, reverse, crypto, forensics, OSINT, misc. Service or downloadable files, flag, solver, writeup, CTFd `challenge.yml` |
| Attack-Defense | a patchable service, a ForcAD / Hackerdom checker, a reference exploit and fix |
| KOTH | a box with foothold, privesc and king file, a king reader, scorer, reset script, team rules |
| Cyber Drill | `machine`: HTB style box with user and root flags. `blue`: incident logs, questions per IR phase, CTFd export |
| TTX | ten-phase scenario, participant pack, facilitator guide, platform export |

Two modes: `workshop` (one item per participant, easy or medium, strict defaults) and `probset`
(packs for a real event, easy to hard, the client's flag format). It pairs with scenario-forge:
scenario-forge designs the exercise, this skill builds and checks it.

## Install

```sh
cd ~
git clone https://github.com/mqusaeri/probset-skills
mkdir -p <skill folder>
cp -r ~/probset-skills/create-chall-lab <skill folder>/
bash ~/probset-skills/create-chall-lab/cek.sh
```

| Harness | Skill folder | Start |
|---|---|---|
| Hermes | `~/.hermes/skills` | `hermes chat -s create-chall-lab` |
| OpenClaw | `~/.openclaw/skills` | `openclaw chat` |
| Claude Code | `~/.claude/skills` | `claude`, then `/create-chall-lab` |
| Codex | `~/.agents/skills` | `codex`, then `$create-chall-lab` |
| OpenCode | `~/.config/opencode/skills` | `opencode` |

## Use

Tell the agent the format, the source idea and the difficulty, for example:

```
/create-chall-lab bikin soal Jeopardy forensics easy dari pola serangan phishing invoice
/create-chall-lab mode probset: servis Attack-Defense medium, flag format ForcAD
/create-chall-lab cyber drill blue: investigasi password spray ke portal karyawan
/create-chall-lab TTX ransomware dari desain scenario-forge ini: <tempel desain>
```

Then check the folder it made:

```sh
bash ~/probset-skills/create-chall-lab/cek-soal.sh <slug>          # satu item
bash ~/probset-skills/create-chall-lab/cek-soal.sh <pack-slug>     # satu pack probset (ada pack.yml)
```

## Repo layout

```
SKILL.md                    router: mode, format, procedure, hard rules
references/                 core-rules, modes, from-scenario-forge, writeup-style
references/formats/         jeopardy, attack-defense, koth, cyber-drill, ttx
templates/<format>/         starting folder per format, each with exercise.yml
cek.sh                      laptop readiness
cek-soal.sh, checks/        item checks, picked by format in exercise.yml
```

## What cek-soal.sh checks

| Format | Checks |
|---|---|
| all | `exercise.yml`, points for the mode and difficulty, flag format and placement, no leftover TODO, pinned base image, safe compose file |
| Jeopardy service | build, run, solver gets the flag from an empty folder, request log. pwn: `dist/chall` equals the container binary |
| Jeopardy files | solver gets the flag from `dist/` alone, flag not in plain bytes of `dist/` |
| Attack-Defense | checker check, put, get return 101, exploit steals the flag, flags survive a restart, the reference patch blocks the exploit and keeps the checker green |
| KOTH | king file owned by root, scorer reads nobody, solver claims the box, reset brings it back |
| Cyber Drill machine | both flags, root flag readable only by root, solver prints both |
| Cyber Drill blue | pack builds, every evidence line and answer is in the logs, no public IPs, no answers in the brief, one CTFd challenge per question |
| TTX | ten canonical phases, canonical roles, three to five options with levels per phase, participant pack without levels or facilitator notes |

A folder without `exercise.yml` is checked as a v1 Jeopardy web challenge, so old workshop
folders still pass.

## Safety

Everything is fictional and runs only in a local Docker lab or an isolated event platform. The
skill declines working exploits for real products outside the lab and malware. See
`references/core-rules.md`.
