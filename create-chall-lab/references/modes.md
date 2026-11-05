# Modes

## workshop (default)

For a participant building one item during a class. Keep it short and safe.

- **One item per run.** One folder, one lesson.
- **Questions:** source, difficulty, author. Nothing else unless the format needs it (category
  for Jeopardy, variant for cyber drill).
- **Difficulty:** easy (100) or medium (200). No hard.
- **Flag format:** `flag{...}`.
- **Hand-off:** the item passes `cek-soal.sh`, then the participant zips the folder and sends it
  to the facilitator, as the lab guide describes.
- **Defaults when unsure:** pick the smaller design. One container, one flaw, one flag, one page
  of writeup.

## probset

For the problem setter building content for a real event or client.

- **Packs.** Many items under one story. Make a pack folder with `pack.yml` and one item folder
  per challenge, service, box, or scenario:

  ```
  <pack-slug>/
  ├── pack.yml              copied from templates/pack.yml
  ├── <item-1>/             each with its own exercise.yml
  ├── <item-2>/
  └── release-plan.md       wave or single-day schedule
  ```

- **Start from a design.** If there is a scenario-forge design, follow
  [from-scenario-forge.md](from-scenario-forge.md). Otherwise draft the item list first (title,
  format, category, difficulty, points, one-line lesson) and confirm it with the user before
  building anything.
- **Difficulty:** easy, medium, or hard, with the probset point ranges in
  [core-rules.md](core-rules.md).
- **Flag format:** ask for the client's convention before building the first item, then set
  `flag_prefix` in every `exercise.yml`. Retrofitting a pack is wasted work.
- **Platform:** CTFd (`challenge.yml`), ForcAD (`forcad-task.yml`), CyberXatria or another
  platform (the `platform/` export in TTX and blue drills). Ask which one.
- **Spread.** Across the pack, balance categories and difficulty, and keep one story tying
  items together even when each is solved alone.
- **Supporting documents:** facilitator guide (docx skill), sponsor workbook (xlsx skill),
  pitch deck (pptx skill), a de-AI pass on prose (humanizer skill).
- **Hand-off:** `cek-soal.sh <pack-slug>` passes for every item. List what goes to the platform
  team and what stays with the facilitator.
