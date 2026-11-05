# probset-skills
AI Skills untuk Problem Setter Cyber Exercise: CTF, Cyber Drill, TTX

Agent skills for people who build cyber exercises. Each skill is a folder you copy into your
agent's skill folder.

| Skill | What it does |
|---|---|
| [create-chall-lab](create-chall-lab/) | Builds and tests exercise content for Jeopardy, Attack-Defense, KOTH, Cyber Drill and TTX. Every item ends as a folder that passes `cek-soal.sh`. |

## Install

```sh
cd ~
git clone https://github.com/mqusaeri/probset-skills
mkdir -p <skill folder>
cp -r ~/probset-skills/create-chall-lab <skill folder>/
bash ~/probset-skills/create-chall-lab/cek.sh
```

The skill folder for Claude Code, Codex, OpenCode, Hermes and OpenClaw is listed in
[create-chall-lab/README.md](create-chall-lab/README.md).

## Safety

Everything here is for authorized training. All content is fictional and runs only in a local
Docker lab or an isolated event platform.
