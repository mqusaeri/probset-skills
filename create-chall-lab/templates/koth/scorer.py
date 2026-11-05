#!/usr/bin/env python3
"""Scorer KOTH. Khusus fasilitator.

  python3 scorer.py HOST:9999 [HOST:9999 ...]            poll tiap 60 detik, cetak tally
  python3 scorer.py --interval 30 HOST:9999 ...           ganti interval
  python3 scorer.py --once HOST:9999 ...                  cetak king sekarang, lalu keluar

Tiap interval, tim yang namanya ada di king.txt sebuah box dapet 1 poin dari box itu.
"""
import argparse
import time
import urllib.request
from collections import Counter


def king(host):
    try:
        with urllib.request.urlopen(f"http://{host}/", timeout=5) as r:
            return r.read().decode(errors="replace").strip()[:64] or "nobody"
    except Exception:  # noqa: BLE001
        return "?down"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("hosts", nargs="+")
    ap.add_argument("--interval", type=int, default=60)
    ap.add_argument("--once", action="store_true")
    a = ap.parse_args()
    if a.once:
        for h in a.hosts:
            print(f"{h}\t{king(h)}")
        return
    tally = Counter()
    rnd = 0
    while True:
        rnd += 1
        kings = {h: king(h) for h in a.hosts}
        for name in kings.values():
            if name not in ("nobody", "?down"):
                tally[name] += 1
        print(f"--- ronde {rnd} {time.strftime('%H:%M:%S')}")
        for h, k in kings.items():
            print(f"  {h:<22} king: {k}")
        print("  skor: " + ", ".join(f"{t}={s}" for t, s in tally.most_common()) if tally else "  skor: belum ada")
        time.sleep(a.interval)


if __name__ == "__main__":
    main()
