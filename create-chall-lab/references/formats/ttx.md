# TTX

A discussion exercise. Roles read a situation, make a decision, and explain why. No Docker. The
structure matches scenario-forge and ttx-report-analyzer, so results can be analysed afterwards
without remapping. Do not change phase names or roles without updating those skills too.

## Layout

```
<slug>/
├── exercise.yml
├── scenario.json        the whole exercise, the single source of truth
├── build_pack.py        copied from the template, builds everything below
├── participant/         built: one file per phase, no levels, no expected answers
├── facilitator/         built: guide.md with every phase, answer levels, timing
└── platform/            built: phases.json for CyberXatria or another platform
```

## Canonical structure

Ten phases, in this order:

| id | Name |
|---|---|
| fase-0 | Context & Urgency Framing |
| fase-1 | Exfiltration Alert Detected |
| fase-2 | Scope & Triage |
| fase-3 | Containment Dilemma |
| fase-4 | Encryption Detonates + Ransom Note |
| fase-5 | Regulator Clock |
| fase-6 | To Pay or Not To Pay |
| fase-7 | Public Disclosure & Comms |
| fase-8 | Recovery & Business Continuity |
| fase-9 | Board & Regulator Debrief |

Seven roles: Crisis Commander, CISO, SOC/IR Lead, IT Infra & Ops, Legal & Compliance,
Corporate Comms, Business/Finance.

If the incident does not fit a ransomware shape, adapt the content of each phase and keep the
ten-phase rhythm. Only set `"custom_phases": true` when the client really needs other names,
and update ttx-report-analyzer in the same pass.

## scenario.json

```json
{
  "title": "Judul TTX",
  "narrative": "PT ...",
  "custom_phases": false,
  "phases": [
    {
      "id": "fase-1",
      "name": "Exfiltration Alert Detected",
      "minutes": 15,
      "roles": ["SOC/IR Lead", "CISO", "IT Infra & Ops"],
      "brief": "Dua sampai empat paragraf, nama sistem dan jam yang spesifik.",
      "prompt": "Keputusan yang harus diambil.",
      "options": [
        {"text": "Pilihan yang masuk akal tapi kurang.", "level": 2},
        {"text": "Pilihan terbaik.", "level": 5},
        {"text": "Pilihan yang kelihatan aman tapi salah.", "level": 1}
      ],
      "why_prompt": "Kenapa kalian pilih itu?",
      "facilitator_notes": "Apa yang dicari dari jawaban, follow-up question."
    }
  ]
}
```

- **Brief:** two to four paragraphs, in the fictional company's voice, with system names and
  times. Not "Server A" and "the attacker".
- **Options:** three to five, levels 0 to 5. Wrong answers must be plausible. A level 3 is a
  real middle ground, not padding. Each phase has at least one option at level 4 or 5 and one
  at 1 or 0.
- **Why prompt:** always. Facilitators grade the reasoning.
- **Roles:** only the roles that would really be pulled into that decision.
- **Scoring:** 0 to 5 per role per phase, partial credit allowed for multi-select. The maturity
  score is the average unless the client wants otherwise. Decide before building.

## build_pack.py

`python3 build_pack.py` writes `participant/`, `facilitator/guide.md`, and
`platform/phases.json`. The participant files show options without levels and in a shuffled,
fixed order. Re-run it after every change to `scenario.json`.

For a docx facilitator guide, give `facilitator/guide.md` to the docx skill, then a humanizer
pass on the prose.

## Checks run by cek-soal.sh

`scenario.json` parses, ten phases with canonical names in order (or `custom_phases`), roles
from the canonical seven, every phase has a brief, prompt, why prompt and three to five options
with levels 0 to 5 including a high and a low, `build_pack.py` runs, and no level numbers or
facilitator notes appear in `participant/`.
