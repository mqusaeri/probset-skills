#!/usr/bin/env python3
"""Bikin paket TTX dari scenario.json. Standard library aja.

Jalanin dari folder item: python3 build_pack.py
Hasil (selalu dibikin ulang, jangan diedit manual):
  participant/    README.md dan satu file per fase. Opsi diacak tetap, tanpa level.
  facilitator/    guide.md: semua fase, opsi dengan level, waktu, catatan fasilitator
  platform/       phases.json buat diimpor ke CyberXatria atau platform lain
"""
import json
import pathlib
import random
import shutil

BASE = pathlib.Path(__file__).resolve().parent
LABELS = "ABCDE"


def fresh(d):
    if d.exists():
        shutil.rmtree(d)
    d.mkdir(parents=True)
    return d


def shuffled(phase):
    opts = list(enumerate(phase["options"]))
    random.Random(phase["id"]).shuffle(opts)
    return [(LABELS[i], o) for i, (_, o) in enumerate(opts)]


def main():
    sc = json.loads((BASE / "scenario.json").read_text())
    phases = sc["phases"]
    part, fac, plat = fresh(BASE / "participant"), fresh(BASE / "facilitator"), fresh(BASE / "platform")

    idx = [f"# {sc['title']}", "", f"{sc.get('narrative', '')}", "", "| Fase | Waktu | Role |", "|---|---|---|"]
    guide = [f"# Panduan fasilitator: {sc['title']}", "", f"Organisasi: {sc.get('narrative', '')}", "",
             f"Total waktu: {sum(p['minutes'] for p in phases)} menit.", "",
             "Skor 0 sampai 5 per role per fase. Nilai alasannya, bukan cuma pilihannya.", ""]
    platform = []
    for p in phases:
        opts = shuffled(p)
        idx.append(f"| {p['name']} | {p['minutes']} menit | {', '.join(p['roles'])} |")
        doc = [f"# {p['name']}", "", f"Waktu: {p['minutes']} menit. Role: {', '.join(p['roles'])}.", "",
               p["brief"], "", f"**Keputusan:** {p['prompt']}", ""]
        doc += [f"- **{lab}.** {o['text']}" for lab, o in opts]
        doc += ["", f"**{p['why_prompt']}**", ""]
        (part / f"{p['id']}.md").write_text("\n".join(doc))
        guide += [f"## {p['name']} ({p['minutes']} menit)", "", f"Role: {', '.join(p['roles'])}", "",
                  p["brief"], "", f"**Keputusan:** {p['prompt']}", "", "| Opsi | Level | Teks |", "|---|---|---|"]
        guide += [f"| {lab} | {o['level']} | {o['text']} |" for lab, o in opts]
        guide += ["", f"**Alasan:** {p['why_prompt']}", "", f"**Catatan:** {p.get('facilitator_notes', '')}", ""]
        platform.append({"id": p["id"], "name": p["name"], "minutes": p["minutes"], "roles": p["roles"],
                         "brief": p["brief"], "prompt": p["prompt"], "why_prompt": p["why_prompt"],
                         "options": [{"label": lab, "text": o["text"], "level": o["level"]} for lab, o in opts]})
    (part / "README.md").write_text("\n".join(idx) + "\n")
    (fac / "guide.md").write_text("\n".join(guide))
    (plat / "phases.json").write_text(json.dumps({"title": sc["title"], "phases": platform}, ensure_ascii=False, indent=2))
    print(f"{len(phases)} fase. participant/, facilitator/guide.md, platform/phases.json siap.")


if __name__ == "__main__":
    main()
