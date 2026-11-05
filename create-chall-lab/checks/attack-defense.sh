# checks/attack-defense.sh: service, checker ForcAD/Hackerdom, exploit, patch

ad_checker() { run_to 30 python3 "$ITEM/checker/checker.py" "$@"; }
ad_flag() { python3 -c "import secrets,string; a=string.ascii_uppercase+string.digits; print('C'+''.join(secrets.choice(a) for _ in range(30))+'=')"; }

# ad_round HOST VULN LABEL -> set AD_FLAG dan AD_FID, return 0 kalau put dan get OK
ad_round() {
  local H="$1" V="$2" L="$3" out rc fid
  AD_FLAG="$(ad_flag)"; fid="$(python3 -c 'import uuid; print(uuid.uuid4().hex[:12])')"
  out="$(ad_checker put "$H" "$fid" "$AD_FLAG" "$V" 2>/dev/null)"; rc=$?
  if [ "$rc" -ne 101 ]; then gagal "$L: checker put vuln $V keluar $rc, bukan 101" "Output: $(printf '%s' "$out" | tail -1)"; return 1; fi
  AD_FID="$(printf '%s' "$out" | tail -1)"; [ -z "$AD_FID" ] && AD_FID="$fid"
  out="$(ad_checker get "$H" "$AD_FID" "$AD_FLAG" "$V" 2>/dev/null)"; rc=$?
  if [ "$rc" -ne 101 ]; then gagal "$L: checker get vuln $V keluar $rc, bukan 101" "Output: $(printf '%s' "$out" | tail -1)"; return 1; fi
  pass "$L: put dan get vuln $V OK (101)"
}

run_ad() {
  local PORT HP H rc out PLACES v
  ITEM="$PWD"; PORT="$(yget port 8080)"
  cek_exercise
  cek_files_exist exercise.yml service/Dockerfile docker-compose.yml checker/checker.py exploit.py patch/fix.patch forcad-task.yml writeup.md
  if [ -f patch/fix.patch ] && ! grep -q '^@@' patch/fix.patch; then gagal "patch/fix.patch masih kosong" "cp -r service service.fixed, perbaiki di service.fixed, lalu diff -ruN service service.fixed > patch/fix.patch"; fi
  PLACES="$(awk '/^[[:space:]]*places:/ {sub(/#.*/, ""); sub(/.*places:[[:space:]]*/, ""); print; exit}' forcad-task.yml 2>/dev/null | tr -dc '0-9')"; PLACES="${PLACES:-1}"
  cek_no_todo checker/checker.py exploit.py writeup.md
  cek_base_image service/Dockerfile
  docker_ready
  compose_checks 1 "$PORT"
  compose_build_up
  HP="$(host_port "$PORT")"; H="127.0.0.1:$HP"
  if wait_tcp 127.0.0.1 "$HP"; then pass "Service jawab di $H"; else gagal "Service nggak jawab di $H" "Cek: docker compose logs"; show_logs; return; fi
  sleep 1
  out="$(ad_checker check "$H" 2>&1)"; rc=$?
  [ "$rc" -eq 101 ] && pass "checker check OK (101)" || { gagal "checker check keluar $rc, bukan 101" "Output: $(printf '%s' "$out" | tail -1)"; return; }

  local flags="" fids="" vs=""
  for v in $(seq 1 "$PLACES"); do
    ad_round "$H" "$v" "Service asli" || return
    flags="$flags $AD_FLAG"; fids="$fids|$AD_FID"; vs="$vs $v"
  done
  out="$(run_to 60 python3 exploit.py "$H" 2>/dev/null)"
  local miss=""
  for f in $flags; do printf '%s' "$out" | grep -Fq "$f" || miss="$miss $f"; done
  [ -z "$miss" ] && pass "exploit.py nyuri semua flag ($PLACES vuln)" || gagal "exploit.py nggak dapet flag dari ${miss}" "Cek exploit.py dan vuln yang dimaksud"

  info "restart service buat cek flag tetap ada"
  docker compose restart >/dev/null 2>&1; wait_tcp 127.0.0.1 "$HP"; sleep 1
  local i=1 f fid
  IFS='|' read -r -a FIDS <<< "${fids#|}"
  for f in $flags; do
    v="$(echo $vs | cut -d' ' -f$i)"; fid="${FIDS[$((i-1))]}"
    ad_checker get "$H" "$fid" "$f" "$v" >/dev/null 2>&1; rc=$?
    [ "$rc" -eq 101 ] && pass "Flag vuln $v masih ada setelah restart" || gagal "Flag vuln $v hilang setelah restart (keluar $rc)" "Simpan data di named volume, bukan di filesystem container"
    i=$((i+1))
  done

  # Patch: salin item, apply fix.patch, jalanin ulang di port yang sama
  info "cek patch referensi"
  docker compose down -v >/dev/null 2>&1
  local T; T="$(mktemp -d)"; TMPS="$TMPS $T"
  cp -r "$ITEM" "$T/item"
  if (cd "$T/item/service" && patch -p1 --quiet < ../patch/fix.patch) >/dev/null 2>&1; then pass "patch/fix.patch ke-apply"
  else gagal "patch/fix.patch nggak bisa di-apply" "Bikin dari folder item: diff -ruN service service.fixed > patch/fix.patch"; return; fi
  cd "$T/item" || return
  export COMPOSE_PROJECT_NAME="cekpatch$(date +%s)"
  if docker compose up -d --build >/dev/null 2>&1; then mark_started; else gagal "Service versi patch gagal jalan" "Cek patch-nya"; cd "$ITEM"; return; fi
  HP="$(host_port "$PORT")"; H="127.0.0.1:$HP"; wait_tcp 127.0.0.1 "$HP"; sleep 1
  ad_checker check "$H" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 101 ] && pass "Versi patch: checker check OK" || gagal "Versi patch: checker check keluar $rc" "Patch-nya ngerusak fitur normal. Perbaikan harus tetap jalan buat user biasa"
  flags=""
  for v in $(seq 1 "$PLACES"); do ad_round "$H" "$v" "Versi patch" && flags="$flags $AD_FLAG"; done
  out="$(run_to 60 python3 "$ITEM/exploit.py" "$H" 2>/dev/null)"
  local leaked=""
  for f in $flags; do printf '%s' "$out" | grep -Fq "$f" && leaked="$leaked $f"; done
  [ -z "$leaked" ] && pass "Versi patch: exploit.py udah nggak dapet flag" || gagal "Versi patch masih bocor" "fix.patch belum nutup semua vuln"
  docker compose down -v --remove-orphans >/dev/null 2>&1
  cd "$ITEM" || return
  unset COMPOSE_PROJECT_NAME
  MANUAL_NOTE="Cek manual: fitur service masuk akal, tiap vuln bisa di-patch tanpa ngerusak checker, writeup cocok."
}
