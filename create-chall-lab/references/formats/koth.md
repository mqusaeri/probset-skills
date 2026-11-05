# King of the Hill

Teams fight over the same box. Whoever has their team name in the king file when the scorer
polls earns points for that interval. Owning the box means getting a foothold, escalating to
root, writing the king file, and then holding it while defending against other teams.

## Layout

```
<slug>/
├── exercise.yml
├── box/
│   ├── Dockerfile       the box: foothold service, privesc path, king reader
│   ├── entrypoint.sh    starts the king reader as root and the foothold service as a low user
│   ├── king_reader.py   root-owned, serves /root/king.txt on port 9999
│   └── app/             the foothold service
├── docker-compose.yml   one service, ports for the foothold service and 9999
├── scorer.py            facilitator-only, polls port 9999 on every box
├── solve.py             facilitator-only, foothold to root, writes a team name
├── reset.sh             puts the box back to a clean state
├── rules.md             shipped to teams: what is allowed while defending
└── writeup.md
```

Probset packs with 2 to 4 hosts: one `koth` item per host, all scored by the same `scorer.py`.

## Box design

- **Foothold:** one service with one intended flaw that gives a low-privilege shell or command
  execution. Port 8080 by default.
- **Privesc:** one intended path to root, for example a misconfigured sudo rule, a writable
  script run by root, a SUID helper, or leaked credentials. State it in the writeup.
- **King file:** `/root/king.txt`, owned by root, mode `644`, so anyone can read it but only
  root can write it. It starts as `nobody`.
- **King reader:** a tiny root process that returns the first line of `/root/king.txt` on port
  9999. It is how the scorer sees the king. Teams must not stop it.
- **Defensible:** a team that owns root can patch the foothold and the privesc, which is the
  point of the game. Leave room for that.

## rules.md (shipped to teams)

Write it plainly. At least:

- Do not stop or block the king reader on port 9999, or the foothold service.
- Do not delete or change `/root/king.txt` into something other than a team name.
- No denial of service against the box, other teams, or the platform.
- Patching, changing passwords, and closing your own way in are allowed.
- Breaking a rule resets the box and can cost points.

## scorer.py

`python3 scorer.py HOST[:PORT] ...` polls every box every `--interval` seconds (default 60) and
prints a running tally. `--once` prints the current king of each box and exits.

## solve.py

`python3 solve.py HOST TEAMNAME` runs foothold to root and writes `TEAMNAME` into the king file,
then prints what it did. Facilitator-only.

## Checks run by cek-soal.sh

1. Build and start the box. Foothold port and port 9999 answer.
2. The king file is owned by root and not writable by others. Scorer reads `nobody`.
3. `solve.py` claims the box as a test team. Scorer reads the test team.
4. `reset.sh` brings the box back. Scorer reads `nobody` again.
5. `rules.md` exists. Compose safety and pinned base image, as in every format.
