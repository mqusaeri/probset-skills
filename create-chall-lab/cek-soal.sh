#!/usr/bin/env bash
# cek-soal.sh v2: cek satu item latihan (atau satu pack) sebelum dikirim.
#   bash ~/create-chall-lab/cek-soal.sh                 dari dalam folder item
#   bash ~/create-chall-lab/cek-soal.sh ~/soal/<slug>   kasih path folder item
#   bash ~/create-chall-lab/cek-soal.sh ~/soal/<pack>   folder pack (ada pack.yml), cek semua item
# Format dibaca dari exercise.yml. Folder tanpa exercise.yml dianggap soal Jeopardy web v1.
# Container selalu dimatiin lagi di akhir.

CHECKS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/checks"
TARGET="${1:-.}"

if [ -f "$TARGET/pack.yml" ]; then
  total=0; bad=""
  for d in "$TARGET"/*/; do
    [ -f "$d/exercise.yml" ] || continue
    total=$((total+1))
    bash "$0" "$d" || bad="$bad $(basename "$d")"
  done
  if [ "$total" -eq 0 ]; then printf "Pack %s belum punya item (folder dengan exercise.yml).\n" "$TARGET"; exit 1; fi
  if [ -z "$bad" ]; then printf "Pack: %d item, semua lolos.\n\n" "$total"; exit 0
  else printf "Pack: %d item, belum lolos:%s\n\n" "$total" "$bad"; exit 1; fi
fi

# shellcheck source=checks/lib.sh
. "$CHECKS/lib.sh"
if ! cd "$TARGET" 2>/dev/null; then printf "Folder %s nggak ketemu.\n" "$TARGET"; exit 1; fi

FORMAT="$(yget format)"
LEGACY=0
if [ ! -f exercise.yml ]; then LEGACY=1; FORMAT="jeopardy"; fi
printf "\n%sCek item: %s%s  (%s)\n\n" "$C_B" "$(basename "$PWD")" "$C_N" "${FORMAT:-format belum diisi}"
[ "$LEGACY" -eq 1 ] && cek "exercise.yml belum ada, dicek sebagai soal Jeopardy web v1" "Salin templates/exercise.yml biar cek-nya sesuai format"

case "$FORMAT" in
  jeopardy)       . "$CHECKS/jeopardy.sh";       run_jeopardy ;;
  attack-defense) . "$CHECKS/attack-defense.sh"; run_ad ;;
  koth)           . "$CHECKS/koth.sh";           run_koth ;;
  cyber-drill)    . "$CHECKS/cyber-drill.sh";    run_drill ;;
  ttx)            . "$CHECKS/ttx.sh";            run_ttx ;;
  *) gagal "format '$FORMAT' nggak dikenal" "Isi format di exercise.yml: jeopardy, attack-defense, koth, cyber-drill, atau ttx" ;;
esac
hasil
