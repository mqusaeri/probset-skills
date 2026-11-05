#!/usr/bin/env python3
"""Bikin paket blue drill dari timeline.json, noise.json, dan questions.json. Standard library aja.

Jalanin dari folder item: python3 build_pack.py
Hasil (selalu dibikin ulang, jangan diedit manual):
  artifacts/      log per host, gabungan event serangan dan noise, urut waktu
  participant/    brief.md, questions.md (tanpa jawaban), artifacts.zip
  facilitator/    answer-key.md, timeline.md
  ctfd/<id>/      challenge.yml per soal (ctfcli), artifacts.zip ikut di soal pertama
"""
import json
import pathlib
import random
import shutil
import zipfile
from collections import defaultdict
from datetime import datetime

BASE = pathlib.Path(__file__).resolve().parent
PHASES = ["Deteksi", "Analisis", "Kontainmen", "Eradikasi", "Pemulihan"]


def load(name, default=None):
    p = BASE / name
    if not p.exists() and default is not None:
        return default
    return json.loads(p.read_text())


def meta(key, default=""):
    p = BASE / "exercise.yml"
    for line in p.read_text().splitlines() if p.exists() else []:
        line = line.split(" #")[0].strip()
        if line.startswith(key + ":"):
            return line.split(":", 1)[1].strip().strip("\"'") or default
    return default


def fresh(d):
    if d.exists():
        shutil.rmtree(d)
    d.mkdir(parents=True)
    return d


def yaml_str(s):
    return json.dumps(str(s), ensure_ascii=False)


def main():
    timeline = load("timeline.json")
    noise = load("noise.json", [])
    questions = load("questions.json")
    author = meta("author", "Nama Tim")

    lines = defaultdict(list)
    for ev in timeline:
        lines[ev["file"]].append((datetime.fromisoformat(ev["t"]), ev["line"]))
    rng = random.Random(1337)
    for rule in noise:
        start, end = datetime.fromisoformat(rule["start"]), datetime.fromisoformat(rule["end"])
        for _ in range(int(rule["count"])):
            dt = start + (end - start) * rng.random()
            vals = {k: rng.choice(v) for k, v in rule.get("values", {}).items()}
            vals["t"] = dt.strftime(rule["time_format"])
            lines[rule["file"]].append((dt, rule["template"].format(**vals)))

    art = fresh(BASE / "artifacts")
    for rel, items in lines.items():
        out = art / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text("\n".join(line for _, line in sorted(items, key=lambda x: x[0])) + "\n")

    part = fresh(BASE / "participant")
    shutil.copy(BASE / "brief.md", part / "brief.md")
    zpath = part / "artifacts.zip"
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
        for f in sorted(art.rglob("*")):
            if f.is_file():
                z.write(f, f.relative_to(art))
    by_phase = defaultdict(list)
    for q in questions:
        by_phase[q["phase"]].append(q)
    order = [p for p in PHASES if p in by_phase] + [p for p in by_phase if p not in PHASES]
    qmd = ["# Soal", "", "Pakai isi artifacts.zip. Jawab sesingkat mungkin, persis seperti di log.", ""]
    for ph in order:
        qmd += [f"## {ph}", ""]
        qmd += [f"- **{q['id']}** ({q.get('points', 100)} poin): {q['question']}" for q in by_phase[ph]]
        qmd.append("")
    (part / "questions.md").write_text("\n".join(qmd))

    fac = fresh(BASE / "facilitator")
    key = ["# Kunci jawaban", "", "Khusus fasilitator.", ""]
    for ph in order:
        key += [f"## {ph}", ""]
        for q in by_phase[ph]:
            ev = q.get("evidence", {})
            src = art / ev.get("file", "")
            hits = [l for l in src.read_text().splitlines() if ev.get("contains", "\0") in l] if src.is_file() else []
            key += [f"### {q['id']}: {q['question']}", "",
                    f"- Jawaban: `{q['answer']}`" + (" (analisis)" if q.get("judgement") else ""),
                    f"- Diterima juga: {', '.join('`%s`' % a for a in q.get('accept', [])) or '-'}",
                    f"- Bukti: `{ev.get('file', '?')}`", ""]
            key += ["```", *hits[:3], "```", ""] if hits else ["(bukti belum ketemu, jalanin cek-soal.sh)", ""]
    (fac / "answer-key.md").write_text("\n".join(key))
    tl = ["# Timeline serangan", "", "| Waktu | File | Fase | Catatan |", "|---|---|---|---|"]
    for ev in sorted(timeline, key=lambda e: datetime.fromisoformat(e["t"])):
        tl.append(f"| {ev['t']} | {ev['file']} | {ev['phase']} | {ev.get('note', '')} |")
    (fac / "timeline.md").write_text("\n".join(tl) + "\n")

    ctfd = fresh(BASE / "ctfd")
    first = None
    for ph in order:
        for i, q in enumerate(by_phase[ph], 1):
            d = ctfd / q["id"]
            d.mkdir()
            flags = [q["answer"]] + [a for a in q.get("accept", []) if a != q["answer"]]
            yml = [f"name: {yaml_str(f'{ph} {i}: ' + q['id'])}", f"author: {yaml_str(author)}",
                   f"category: {yaml_str(ph)}",
                   f"description: {yaml_str(q['question'] + ('' if first is None else f' Artefak ada di soal {first}.'))}",
                   f"value: {int(q.get('points', 100))}", "type: standard", "flags:"]
            yml += [f"  - {{type: static, content: {yaml_str(f)}, data: case_insensitive}}" for f in flags]
            if first is None:
                (d / "dist").mkdir()
                shutil.copy(zpath, d / "dist" / "artifacts.zip")
                yml += ["files:", "  - dist/artifacts.zip"]
                first = f"{ph} {i}"
            yml += ["state: visible", 'version: "0.1"']
            (d / "challenge.yml").write_text("\n".join(yml) + "\n")
    n = sum(len(v) for v in lines.values())
    print(f"artifacts: {len(lines)} file, {n} baris. soal: {len(questions)}. paket siap.")


if __name__ == "__main__":
    main()
