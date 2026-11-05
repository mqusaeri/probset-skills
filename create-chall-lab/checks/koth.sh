# checks/koth.sh: box, king reader, scorer, solve, reset

koth_king() { run_to 15 python3 scorer.py --once "127.0.0.1:$1" 2>&1; }

run_koth() {
  local PORT KPORT HP KP perm out
  PORT="$(yget port 8080)"; KPORT="$(yget king_port 9999)"
  cek_exercise
  cek_files_exist exercise.yml box/Dockerfile box/entrypoint.sh box/king_reader.py docker-compose.yml scorer.py solve.py reset.sh rules.md writeup.md
  cek_no_todo solve.py rules.md writeup.md
  cek_base_image box/Dockerfile
  docker_ready
  compose_checks 1 "$PORT" "$KPORT"
  compose_build_up
  HP="$(host_port "$PORT")"; KP="$(host_port "$KPORT")"
  if wait_http "http://localhost:$HP" || wait_tcp 127.0.0.1 "$HP"; then pass "Service foothold jawab di port $HP"; else gagal "Service foothold nggak jawab di port $HP" "Cek: docker compose logs"; show_logs; return; fi
  if wait_http "http://localhost:$KP"; then pass "King reader jawab di port $KP"; else gagal "King reader nggak jawab di port $KP" "entrypoint.sh harus jalanin king_reader.py sebagai root"; show_logs; return; fi
  perm="$(docker compose exec -T "$SVC" stat -c '%U %a' /root/king.txt 2>/dev/null | tr -d '\r')"
  case "$perm" in
    "root "[0-7][0-7][0-7]) case "${perm#root }" in ?[0145][0145]) pass "king.txt punya root, nggak bisa ditulis user lain ($perm)" ;; *) gagal "king.txt bisa ditulis selain root ($perm)" "chmod 644 /root/king.txt" ;; esac ;;
    *) gagal "king.txt nggak ketemu atau bukan punya root (${perm:-kosong})" "Bikin /root/king.txt isi nobody di entrypoint.sh" ;;
  esac
  out="$(koth_king "$KP")"
  printf '%s' "$out" | grep -q 'nobody' && pass "Scorer baca king awal: nobody" || gagal "Scorer nggak baca nobody di awal" "Output: $(printf '%s' "$out" | tail -1)"
  out="$(run_to 120 python3 solve.py "127.0.0.1:$HP" cek-team 2>&1)"
  sleep 1
  if koth_king "$KP" | grep -q 'cek-team'; then pass "solve.py berhasil jadi king (cek-team)"
  else gagal "Setelah solve.py, king bukan cek-team" "Output solve: $(printf '%s' "$out" | tail -1)"; fi
  info "jalanin reset.sh"
  if run_to 180 bash reset.sh >/dev/null 2>&1; then
    wait_http "http://localhost:$(host_port "$KPORT")"; wait_http "http://localhost:$(host_port "$PORT")"
    koth_king "$(host_port "$KPORT")" | grep -q 'nobody' && pass "reset.sh balikin box ke awal (nobody)" || gagal "Setelah reset.sh, king bukan nobody" "reset.sh harus build ulang container dari nol"
  else gagal "reset.sh gagal" "Jalanin manual: bash reset.sh"; fi
  MANUAL_NOTE="Cek manual: privesc cuma satu jalur yang dimaksud, rules.md jelas, box bisa dipertahankan setelah di-patch."
}
