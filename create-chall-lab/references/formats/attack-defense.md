# Attack-Defense

Every team runs the same vulnerable service. Each round the checker stores a fresh flag in every
team's service and later checks it is still there and the service still works. Teams steal
flags from other teams and patch their own copy without breaking it. Target platform: ForcAD
(the checker also follows the Hackerdom interface most A/D platforms use).

## Layout

```
<slug>/
├── exercise.yml
├── service/             what every team gets, source included
│   ├── Dockerfile
│   └── app/
├── docker-compose.yml   one service, one named volume for its data
├── checker/checker.py   facilitator-only, ForcAD / Hackerdom checker
├── exploit.py           facilitator-only, proves the intended vuln works
├── patch/fix.patch      facilitator-only, the reference fix (patch -p1 inside service/)
├── forcad-task.yml      the task block for ForcAD config.yml
└── writeup.md           vuln, exploit idea, fix
```

## Service design

- One small, believable feature that stores data per user: notes, tickets, invoices, a parcel
  tracker. Flags are stored as that data, so stealing a flag means abusing the feature.
- One or two intended vulns, each tied to a `vuln` number the checker uses. Workshop mode: one.
- State in a named volume so flags survive a restart. The checker treats lost flags as
  `CORRUPT`, so a service that forgets data on restart is broken.
- Patchable: a team must be able to fix each vuln in a few lines without breaking the checker's
  normal flow. Write that fix in `patch/fix.patch` and prove it. Make it from the item folder:
  `cp -r service service.fixed`, fix the copy, `diff -ruN service service.fixed > patch/fix.patch`,
  then delete `service.fixed`.
- No hidden admin backdoor, no rate limit that would block the checker, no outbound calls.
- Logs one line per request.

## Checker contract

```
python3 checker/checker.py check HOST
python3 checker/checker.py put   HOST FLAG_ID FLAG VULN
python3 checker/checker.py get   HOST FLAG_ID FLAG VULN
```

| Exit | Status | Meaning |
|---|---|---|
| 101 | OK | works |
| 102 | CORRUPT | service works but the flag from an earlier round is gone (`get` only) |
| 103 | MUMBLE | service answers wrong |
| 104 | DOWN | cannot connect |
| 110 | CHECKER_ERROR | the checker itself failed |

- `put` prints the data `get` will need (for example the username and password it registered)
  to stdout as one line. ForcAD passes that line back to `get` as `FLAG_ID`.
- stdout on a failed run is shown on the scoreboard, so keep it short and blame-free. Debug
  details go to stderr.
- `check` exercises the normal features a real user would, not just the home page. A team that
  "patches" by deleting the feature must fail `check`.
- Standard library only, HOST may include a port (`10.10.1.2:8080`). Each action finishes in a
  few seconds.

## Flags

ForcAD makes the flags. The default looks like `[A-Z0-9]{31}=`. The checker and exploit must
accept any flag string, so do not hard-code a format. There is no `flag.txt` in this format.

## exploit.py

`python3 exploit.py HOST` prints every flag it can steal from that host, one per line. It is
the facilitator's proof that the vuln is real, and it is never shipped.

## forcad-task.yml

```yaml
- name: nama-servis
  checker: nama-servis/checker.py
  checker_type: hackerdom
  checker_timeout: 10
  puts: 1
  gets: 1
  places: 1        # number of vulns, VULN is picked in [1, places]
```

## Checks run by cek-soal.sh

1. Build and start the service.
2. `check` returns 101.
3. `put` a random flag returns 101, `get` with the printed `FLAG_ID` returns 101.
4. `exploit.py` prints that flag.
5. Restart the service, `get` still returns 101 (flags persist).
6. Apply `patch/fix.patch` to a copy, rebuild: `check`, `put`, `get` all 101, and `exploit.py`
   no longer prints the new flag.
7. Compose safety and pinned base image, as in every format.
