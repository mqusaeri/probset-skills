# Building from a scenario-forge design

scenario-forge produces the plan: narrative, technical design, scoring model, facilitator
documentation, and platform spec. This skill builds the parts that must run or be checked. Read
the design first, then map it like this.

| scenario-forge gives | Goes into |
|---|---|
| narrative bank entry (company, sector, why attacked) | `narrative` in every `exercise.yml`, and `pack.yml` |
| Jeopardy per-challenge checklist (title, category, difficulty, points, blurb, files or environment, flag format, hints) | one `jeopardy` item per challenge. Blurb goes to `challenge.yml` description, files or environment decide `delivery` |
| Jeopardy release model | `release-plan.md` in the pack |
| KOTH target infrastructure (2 to 4 hosts) | one `koth` item per host, plus the shared `scorer.py` settings in `pack.yml` |
| KOTH scoring service and check interval | `scorer.py` interval and `rules.md` |
| Cyber drill machine build spec and attack chain | one `cyber-drill` item, `variant: machine` |
| Cyber drill blue-team or SOC scenario | one `cyber-drill` item, `variant: blue` |
| TTX phases, roles, answer options with levels, scoring | `scenario.json` in a `ttx` item |
| facilitator guide content | `writeup.md`, `walkthrough.md`, or `facilitator/` |
| platform content spec | `challenge.yml`, `forcad-task.yml`, or `platform/` |

## Rules

- Keep the design's names, difficulty, and points unless they break a rule here. If they do,
  say which rule and propose the smallest change.
- Build in the design's order and run `cek-soal.sh` after each item, not only at the end.
- If the design leaves something open (a flag format, a port, a check interval), ask once for
  the whole pack.
- After the build, add anything new (a fictional company, a host name scheme) back to the
  narrative bank through scenario-forge, so the next event can reuse it.
