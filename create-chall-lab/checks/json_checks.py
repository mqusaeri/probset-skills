#!/usr/bin/env python3
"""Checks that are easier in Python than in bash. Standard library only.

  python3 json_checks.py ips PATH...      print public IPv4 addresses found in text files
  python3 json_checks.py blue ITEM_DIR    validate a blue cyber drill item (after build_pack.py)
  python3 json_checks.py ttx ITEM_DIR     validate a TTX item (after build_pack.py)

blue and ttx print one result per line: OK|GAGAL|CEK <tab> message <tab> hint
"""
import ipaddress
import json
import pathlib
import re
import sys
from datetime import datetime

IP_RE = re.compile(r"(?<![\d.])(\d{1,3}(?:\.\d{1,3}){3})(?![\d.])")
TEXT_EXT = {".log", ".txt", ".json", ".md", ".csv", ".yml", ".yaml", ".xml", ".evtx.json", ".conf", ".jsonl", ""}

PHASES_TTX = [
    ("fase-0", "Context & Urgency Framing"),
    ("fase-1", "Exfiltration Alert Detected"),
    ("fase-2", "Scope & Triage"),
    ("fase-3", "Containment Dilemma"),
    ("fase-4", "Encryption Detonates + Ransom Note"),
    ("fase-5", "Regulator Clock"),
    ("fase-6", "To Pay or Not To Pay"),
    ("fase-7", "Public Disclosure & Comms"),
    ("fase-8", "Recovery & Business Continuity"),
    ("fase-9", "Board & Regulator Debrief"),
]
ROLES_TTX = {"Crisis Commander", "CISO", "SOC/IR Lead", "IT Infra & Ops", "Legal & Compliance",
             "Corporate Comms", "Business/Finance"}
PHASES_IR = ["Deteksi", "Analisis", "Kontainmen", "Eradikasi", "Pemulihan"]

out = []


def res(kind, msg, hint=""):
    out.append(f"{kind}\t{msg}\t{hint}")


def text_files(paths):
    for p in paths:
        p = pathlib.Path(p)
        files = [p] if p.is_file() else sorted(x for x in p.rglob("*") if x.is_file())
        for f in files:
            if f.suffix.lower() in TEXT_EXT or f.name.endswith(".log"):
                yield f


def public_ips(paths):
    found = []
    for f in text_files(paths):
        try:
            data = f.read_text(errors="replace")
        except OSError:
            continue
        for m in IP_RE.finditer(data):
            try:
                ip = ipaddress.ip_address(m.group(1))
            except ValueError:
                continue
            if ip.is_global:
                found.append(f"{ip} ({f})")
    return sorted(set(found))


def load_json(path, what):
    try:
        return json.loads(pathlib.Path(path).read_text())
    except FileNotFoundError:
        res("GAGAL", f"{what} belum ada", f"Salin dari template lalu isi")
    except json.JSONDecodeError as e:
        res("GAGAL", f"{what} bukan JSON yang valid: baris {e.lineno} kolom {e.colno}", "Cek koma dan tanda kutip")
    return None


def all_text(folder):
    return "\n".join(f.read_text(errors="replace") for f in text_files([folder])) if folder.exists() else ""


def check_blue(item):
    item = pathlib.Path(item)
    tl = load_json(item / "timeline.json", "timeline.json")
    qs = load_json(item / "questions.json", "questions.json")
    if tl is None or qs is None:
        return
    bad_t = [e for e in tl if not _iso(e.get("t", ""))]
    missing = [i for i, e in enumerate(tl) if not all(k in e for k in ("t", "file", "line", "phase"))]
    if missing:
        res("GAGAL", f"Event timeline nomor {missing[:5]} kurang key", "Tiap event butuh t, file, line, phase")
    elif bad_t:
        res("GAGAL", f"{len(bad_t)} event punya waktu yang nggak kebaca", "Pakai ISO 8601, contoh 2026-11-05T09:14:03+07:00")
    else:
        res("OK", f"timeline.json valid ({len(tl)} event)")
    if any(".." in e.get("file", "") or e.get("file", "").startswith("/") for e in tl):
        res("GAGAL", "Path file di timeline keluar dari artifacts/", "Pakai path relatif, contoh web-01/access.log")

    art = item / "artifacts"
    if not art.is_dir():
        res("GAGAL", "artifacts/ belum ada", "Jalanin python3 build_pack.py dulu")
        return
    ids = [q.get("id") for q in qs]
    if len(ids) != len(set(ids)):
        res("GAGAL", "Ada id soal yang dobel", "Tiap soal id-nya beda, contoh q1, q2")
    phases = {q.get("phase") for q in qs}
    unknown = phases - set(PHASES_IR)
    if unknown:
        res("CEK", f"Fase di luar alur IR: {sorted(unknown)}", f"Pakai {', '.join(PHASES_IR)}")
    for need in ("Deteksi", "Analisis"):
        if need not in phases:
            res("GAGAL", f"Belum ada soal fase {need}", "Minimal satu soal per fase yang dicakup drill")
    if len(phases & set(PHASES_IR)) >= 3:
        res("OK", f"Soal mencakup {len(phases & set(PHASES_IR))} fase IR")
    else:
        res("CEK", f"Soal baru mencakup {len(phases & set(PHASES_IR))} fase IR", "Idealnya Deteksi sampai Kontainmen atau lebih")

    alltxt = all_text(art)
    ev_bad, ans_bad = [], []
    for q in qs:
        ev = q.get("evidence") or {}
        f = art / ev.get("file", "__missing__")
        content = f.read_text(errors="replace") if f.is_file() else ""
        if not ev.get("contains") or ev["contains"] not in content:
            ev_bad.append(q.get("id"))
        if not q.get("judgement"):
            answers = [q.get("answer", "")] + list(q.get("accept", []))
            if not any(a and a in alltxt for a in answers):
                ans_bad.append(q.get("id"))
    if ev_bad:
        res("GAGAL", f"Evidence nggak ketemu di artifacts buat soal {ev_bad}", "evidence.contains harus persis ada di evidence.file")
    else:
        res("OK", "Semua evidence ketemu di artifacts")
    if ans_bad:
        res("GAGAL", f"Jawaban nggak ada di artifacts buat soal {ans_bad}", "Kalau jawabannya analisis, set \"judgement\": true")
    else:
        res("OK", "Semua jawaban faktual bisa dibuktiin dari artifacts")

    # Answers belong inside the artifacts (that is the investigation), never in the brief or question list.
    part = item / "participant"
    qmd = (part / "questions.md").read_text(errors="replace") if (part / "questions.md").is_file() else ""
    brief = (item / "brief.md").read_text(errors="replace") if (item / "brief.md").is_file() else ""
    leaks = [q.get("id") for q in qs if len(str(q.get("answer", ""))) >= 4
             and (str(q["answer"]) in qmd or str(q["answer"]) in brief)]
    if not qmd:
        res("GAGAL", "participant/questions.md belum ada", "Jalanin python3 build_pack.py")
    elif leaks:
        res("GAGAL", f"Jawaban bocor di brief atau daftar soal: {sorted(set(leaks))}", "Hapus jawaban dari brief.md atau question")
    else:
        res("OK", "Jawaban nggak bocor di brief dan daftar soal")
    ctfd = item / "ctfd"
    n = len(list(ctfd.glob("*/challenge.yml"))) if ctfd.is_dir() else 0
    if n == len(qs):
        res("OK", f"ctfd/ punya {n} challenge, sama dengan jumlah soal")
    else:
        res("GAGAL", f"ctfd/ punya {n} challenge, soalnya {len(qs)}", "Jalanin python3 build_pack.py lagi")


def _iso(s):
    try:
        datetime.fromisoformat(s)
        return True
    except (TypeError, ValueError):
        return False


def check_ttx(item):
    item = pathlib.Path(item)
    sc = load_json(item / "scenario.json", "scenario.json")
    if sc is None:
        return
    phases = sc.get("phases", [])
    if sc.get("custom_phases"):
        res("CEK", "custom_phases aktif, nama fase nggak dicek", "Update mapping ttx-report-analyzer juga")
    else:
        got = [(p.get("id"), p.get("name")) for p in phases]
        if got == PHASES_TTX:
            res("OK", "10 fase kanonik, urutan benar")
        else:
            res("GAGAL", "Fase belum sesuai 10 fase kanonik", "Ikutin tabel di references/formats/ttx.md, id dan nama persis")
    bad_roles = sorted({r for p in phases for r in p.get("roles", [])} - ROLES_TTX)
    if bad_roles:
        res("GAGAL", f"Role di luar 7 role kanonik: {bad_roles}", "Pakai nama role persis dari references/formats/ttx.md")
    else:
        res("OK", "Semua role pakai nama kanonik")
    problems = []
    for p in phases:
        pid = p.get("id", "?")
        if len(p.get("brief", "")) < 200:
            problems.append(f"{pid}: brief terlalu pendek")
        if not p.get("prompt"):
            problems.append(f"{pid}: prompt kosong")
        if not p.get("why_prompt"):
            problems.append(f"{pid}: why_prompt kosong")
        if not p.get("roles"):
            problems.append(f"{pid}: belum ada role")
        opts = p.get("options", [])
        levels = [o.get("level") for o in opts]
        if not 3 <= len(opts) <= 5:
            problems.append(f"{pid}: opsi harus 3 sampai 5")
        if any(not isinstance(l, int) or not 0 <= l <= 5 for l in levels):
            problems.append(f"{pid}: level harus angka 0 sampai 5")
        elif levels and (max(levels) < 4 or min(levels) > 1):
            problems.append(f"{pid}: butuh satu opsi level 4 atau 5 dan satu level 0 atau 1")
        if not isinstance(p.get("minutes"), int) or p.get("minutes", 0) <= 0:
            problems.append(f"{pid}: minutes belum diisi")
    if problems:
        res("GAGAL", f"{len(problems)} masalah di fase: " + "; ".join(problems[:4]), "Lengkapi scenario.json")
    else:
        res("OK", "Tiap fase lengkap: brief, prompt, why prompt, 3 sampai 5 opsi dengan level")
    total = sum(p.get("minutes", 0) for p in phases if isinstance(p.get("minutes"), int))
    res("OK", f"Total durasi {total} menit")

    part = item / "participant"
    if not part.is_dir() or not any(part.iterdir()):
        res("GAGAL", "participant/ belum ada", "Jalanin python3 build_pack.py")
        return
    ptxt = all_text(part)
    leak = []
    if re.search(r"\b(level|skor|score)\s*[:=]?\s*[0-5]\b", ptxt, re.I):
        leak.append("angka level")
    for p in phases:
        note = (p.get("facilitator_notes") or "").strip()
        if len(note) >= 12 and note in ptxt:
            leak.append(f"catatan fasilitator {p.get('id')}")
    if leak:
        res("GAGAL", f"Paket peserta bocor: {', '.join(leak)}", "Jalanin ulang build_pack.py, jangan edit participant/ manual")
    else:
        res("OK", "Paket peserta bersih dari level dan catatan fasilitator")
    if (item / "facilitator" / "guide.md").is_file():
        res("OK", "facilitator/guide.md ada")
    else:
        res("GAGAL", "facilitator/guide.md belum ada", "Jalanin python3 build_pack.py")
    if load_json(item / "platform" / "phases.json", "platform/phases.json") is not None:
        res("OK", "platform/phases.json valid")


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    cmd, args = sys.argv[1], sys.argv[2:]
    if cmd == "ips":
        for line in public_ips(args):
            print(line)
        return
    {"blue": check_blue, "ttx": check_ttx}[cmd](args[0])
    print("\n".join(out))


if __name__ == "__main__":
    main()
