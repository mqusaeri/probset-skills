# checks/ttx.sh

run_ttx() {
  cek_exercise
  cek_files_exist exercise.yml scenario.json build_pack.py
  [ -f scenario.json ] || return
  local blog
  if blog="$(run_to 60 python3 build_pack.py 2>&1)"; then pass "build_pack.py jalan"
  else gagal "build_pack.py gagal" "$(printf '%s' "$blog" | tail -1)"; return; fi
  json_results < <(python3 "$CHECKS/json_checks.py" ttx .)
  cek_ips scenario.json
  cek_no_todo scenario.json
  MANUAL_NOTE="Cek manual: opsi salah tetap masuk akal, brief pakai nama fiktif, nada bahasa natural."
}
