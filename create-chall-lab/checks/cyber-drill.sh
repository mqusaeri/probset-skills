# checks/cyber-drill.sh: variant machine dan blue

run_drill() {
  local VAR; VAR="$(yget variant)"
  case "$VAR" in
    machine) cek_exercise; drill_machine ;;
    blue)    cek_exercise; drill_blue ;;
    *) gagal "variant '$VAR' nggak dikenal" "Isi variant: machine atau blue" ;;
  esac
}

drill_machine() {
  local PORT HP U R sout perm UF RF
  PORT="$(yget port 8080)"
  cek_files_exist exercise.yml Dockerfile entrypoint.sh app docker-compose.yml flags/user.txt flags/root.txt solve.py brief.md walkthrough.md
  cek_flag_file flags/user.txt; U="$FLAG"
  cek_flag_file flags/root.txt; R="$FLAG"
  [ -n "$U" ] && [ "$U" = "$R" ] && gagal "User flag sama dengan root flag" "Bikin dua flag yang beda"
  FLAG="$U"; cek_no_leak "app/ dan brief.md (user flag)" app brief.md
  FLAG="$R"; cek_no_leak "app/ dan brief.md (root flag)" app brief.md
  cek_solver_no_peek solve.py
  cek_ips brief.md walkthrough.md
  cek_no_todo brief.md walkthrough.md
  cek_base_image Dockerfile
  docker_ready
  compose_checks 1 "$PORT"
  compose_build_up
  HP="$(host_port "$PORT")"
  if wait_http "http://localhost:$HP"; then pass "Mesin jawab di port $HP"
  elif wait_tcp 127.0.0.1 "$HP"; then pass "Mesin jawab di port $HP (TCP)"
  else gagal "Mesin nggak jawab di port $HP" "Cek: docker compose logs"; show_logs; return; fi
  RF="$(yget root_flag_path /root/root.txt)"
  perm="$(docker compose exec -T "$SVC" stat -c '%U %a' "$RF" 2>/dev/null | tr -d '\r')"
  case "$perm" in
    "root "[0-7]00) pass "Root flag cuma bisa dibaca root ($perm)" ;;
    *) gagal "Root flag di $RF nggak aman (${perm:-nggak ketemu})" "chown root:root dan chmod 400" ;;
  esac
  sout="$(run_solver 120 "http://localhost:$HP" 2>&1)"
  if printf '%s' "$sout" | grep -Fq "$U" && printf '%s' "$sout" | grep -Fq "$R"; then pass "solve.py dapet user flag dan root flag"
  else gagal "solve.py belum dapet dua flag" "Output: $(printf '%s' "$sout" | tail -2 | tr '\n' ' ')"; fi
  cek_request_log
  MANUAL_NOTE="Cek manual: brief.md nol spoiler, walkthrough cocok dengan solve, tingkat kesulitan sesuai customer."
}

drill_blue() {
  local blog
  cek_files_exist exercise.yml timeline.json noise.json questions.json brief.md build_pack.py
  [ -f timeline.json ] && [ -f questions.json ] || return
  if blog="$(run_to 120 python3 build_pack.py 2>&1)"; then pass "build_pack.py jalan"
  else gagal "build_pack.py gagal" "$(printf '%s' "$blog" | tail -1)"; return; fi
  json_results < <(python3 "$CHECKS/json_checks.py" blue .)
  cek_ips artifacts brief.md questions.json
  cek_no_todo timeline.json questions.json brief.md
  MANUAL_NOTE="Cek manual: cerita serangan konsisten antar host, noise realistis, jawaban nggak ambigu."
}
