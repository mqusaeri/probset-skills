# checks/jeopardy.sh: web, pwn, reverse, crypto, forensics, osint, misc

run_jeopardy() {
  local CAT DEL PORT SRC
  CAT="$(yget category web)"; DEL="$(yget delivery)"; PORT="$(yget port)"
  case "$CAT" in
    web|pwn) [ -z "$DEL" ] && DEL=service ;;
    reverse|crypto|forensics) [ -z "$DEL" ] && DEL=files ;;
    osint|misc) [ -z "$DEL" ] && DEL=service ;;
    *) gagal "category '$CAT' nggak dikenal" "Pilih web, pwn, reverse, crypto, forensics, osint, atau misc"; return ;;
  esac
  case "$CAT:$DEL" in
    web:files|pwn:files) gagal "Category $CAT harus delivery service" "Isi delivery: service"; return ;;
    reverse:service|crypto:service|forensics:service) gagal "Category $CAT harus delivery files" "Isi delivery: files"; return ;;
  esac
  [ "$CAT" = "pwn" ] && SRC=src || SRC=app
  [ -z "$PORT" ] && { [ "$CAT" = "pwn" ] && PORT=1337 || PORT=8080; }
  pass "Jeopardy $CAT, delivery $DEL"

  if [ "$LEGACY" -eq 1 ]; then MODE=workshop; DIFF=easy; POINTS=""; FLAG_PREFIX=flag; else cek_exercise; fi

  if [ "$DEL" = "service" ]; then
    if [ "$CAT" = "pwn" ]; then cek_files_exist src Dockerfile docker-compose.yml dist flag.txt solve.py writeup.md challenge.yml
    else cek_files_exist "$SRC" Dockerfile docker-compose.yml flag.txt solve.py writeup.md challenge.yml; fi
  else
    cek_files_exist dist flag.txt solve.py writeup.md challenge.yml
  fi

  cek_flag_file flag.txt
  if [ -f challenge.yml ]; then
    [ -n "$FLAG" ] && { grep -Fq "$FLAG" challenge.yml && pass "Flag di challenge.yml sama dengan flag.txt" || gagal "Flag di challenge.yml beda dengan flag.txt" "Samain persis, termasuk huruf besar kecil"; }
    if grep -Eq "^category:[[:space:]]*\"?$CAT\"?[[:space:]]*(#.*)?$" challenge.yml; then pass "Category di challenge.yml: $CAT"
    else gagal "category di challenge.yml bukan $CAT" "Isi category: $CAT"; fi
    local val; val="$(awk -F': *' '/^value:/ {print $2; exit}' challenge.yml | tr -d '" ')"
    if [ -n "$POINTS" ]; then
      [ "$val" = "$POINTS" ] && pass "Value di challenge.yml sama dengan points ($val)" || gagal "value di challenge.yml ($val) beda dengan points ($POINTS)" "Samain value dengan points di exercise.yml"
    else
      case "$val" in 100|200) pass "Value $val" ;; *) gagal "value di challenge.yml bukan 100 atau 200" "Easy 100, Medium 200" ;; esac
    fi
    [ "$DEL" = "service" ] && { grep -q '^connection_info:' challenge.yml || cek "connection_info belum ada" "Fasilitator yang isi alamatnya, tulis placeholder dulu"; }
  fi
  [ "$DEL" = "service" ] && cek_no_leak "kode $SRC/" "$SRC"
  cek_solver_no_peek solve.py
  cek_no_todo challenge.yml writeup.md

  if [ "$DEL" = "files" ]; then
    jeopardy_files "$CAT"
  else
    jeopardy_service "$CAT" "$PORT"
  fi
}

jeopardy_files() {
  local CAT="$1" n
  n="$(find dist -type f ! -name '.gitkeep' 2>/dev/null | grep -c .)"
  if [ "$n" -gt 0 ]; then pass "dist/ berisi $n file buat peserta"; else gagal "dist/ masih kosong" "Jalanin build/gen.py buat bikin file soal"; return; fi
  local missing=""
  for f in $(awk '/^files:/ {f=1; next} f && /^[[:space:]]*-/ {gsub(/^[[:space:]]*-[[:space:]]*|"/, ""); print; next} f && /^[^[:space:]]/ {f=0}' challenge.yml); do
    [ -e "$f" ] || missing="$missing $f"
  done
  [ -z "$missing" ] && pass "File di challenge.yml ada semua" || gagal "File di challenge.yml nggak ada:$missing" "Path relatif ke folder soal, contoh dist/soal.bin"
  if [ -n "$FLAG" ] && python3 - "$FLAG" dist <<'PY'
import pathlib, sys
flag = sys.argv[1].encode()
sys.exit(0 if any(flag in p.read_bytes() for p in pathlib.Path(sys.argv[2]).rglob('*') if p.is_file()) else 1)
PY
  then
    case "$CAT" in
      reverse|crypto) gagal "Flag kelihatan polos di dist/" "Peserta tinggal strings. Sembunyiin sesuai pelajarannya" ;;
      *) cek "Flag kelihatan polos di dist/" "Oke kalau memang itu pelajarannya (easy). Tulis di writeup" ;;
    esac
  else pass "Flag nggak kelihatan polos di dist/"; fi
  local T; T="$(mktemp -d)"; TMPS="$TMPS $T"
  cp solve.py "$T/" && cp -r dist "$T/"
  local sout src
  sout="$(cd "$T" && run_to 60 python3 solve.py dist 2>&1)"; src=$?
  if [ -n "$FLAG" ] && printf '%s' "$sout" | grep -Fq "$FLAG"; then pass "solve.py dapet flag cuma dari dist/"
  elif [ "$src" -eq 124 ]; then gagal "solve.py lebih dari 60 detik" "Solver harus cepat dan nggak nunggu input"
  else gagal "solve.py nggak ngeluarin flag kalau cuma dikasih dist/" "Kasih output di bawah ke agent buat dibenerin"; printf '%s\n' "$sout" | tail -8 | sed 's/^/         /'; fi
}

jeopardy_service() {
  local CAT="$1" PORT="$2" HP TARGET
  cek_base_image Dockerfile
  docker_ready
  compose_checks 1 "$PORT"
  compose_build_up
  HP="$(host_port "$PORT")"
  if [ "$CAT" = "pwn" ]; then
    if wait_tcp 127.0.0.1 "$HP"; then pass "Service jawab di 127.0.0.1:$HP"; else gagal "Service nggak jawab di port $HP setelah 30 detik" "Cek: docker compose logs"; show_logs; return; fi
    TARGET="127.0.0.1:$HP"
    local BIN T; BIN="$(yget binary /home/ctf/chall)"; T="$(mktemp -d)"; TMPS="$TMPS $T"
    if [ -f dist/chall ] && docker compose cp "$SVC:$BIN" "$T/chall" >/dev/null 2>&1; then
      if cmp -s dist/chall "$T/chall"; then pass "dist/chall sama persis dengan binary di container"
      else gagal "dist/chall beda dengan binary di container" "Jalanin bash make-dist.sh, lalu cek lagi"; fi
    else gagal "Nggak bisa bandingin dist/chall dengan $BIN di container" "Cek path binary, atau isi binary: di exercise.yml"; fi
  else
    TARGET="http://localhost:$HP"
    if wait_http "$TARGET"; then pass "App jawab di $TARGET (HTTP $HTTP_CODE)"
    else gagal "App nggak jawab di $TARGET setelah 30 detik" "Biasanya app dengerin 127.0.0.1 atau crash. Cek: docker compose logs"; show_logs; return; fi
  fi
  local sout src
  sout="$(run_solver 60 "$TARGET" 2>&1)"; src=$?
  if [ -n "$FLAG" ] && printf '%s' "$sout" | grep -Fq "$FLAG"; then pass "solve.py dapet flag yang bener"
  elif [ "$src" -eq 124 ]; then gagal "solve.py lebih dari 60 detik" "Solver harus cepat dan nggak nunggu input"
  else gagal "solve.py nggak ngeluarin flag yang ada di flag.txt" "Kasih output di bawah ke agent buat dibenerin"; printf '%s\n' "$sout" | tail -10 | sed 's/^/         /'; fi
  if [ "$CAT" = "pwn" ]; then cek_request_log 'accepting connection|connection from'; else cek_request_log; fi
  MANUAL_NOTE="Cek manual: writeup cocok dengan solve, level pas, semua nama fiktif."
}
