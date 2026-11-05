# checks/lib.sh: helper bersama buat cek-soal.sh. Di-source, bukan dijalanin langsung.

ok=0; fail=0; warn=0
if [ -t 1 ]; then C_G=$'\033[32m'; C_R=$'\033[31m'; C_Y=$'\033[33m'; C_B=$'\033[1m'; C_N=$'\033[0m'; else C_G=; C_R=; C_Y=; C_B=; C_N=; fi
pass()  { printf "  %sOK%s     %s\n" "$C_G" "$C_N" "$1"; ok=$((ok+1)); }
gagal() { printf "  %sGAGAL%s  %s\n" "$C_R" "$C_N" "$1"; [ -n "$2" ] && printf "         Coba: %s\n" "$2"; fail=$((fail+1)); }
cek()   { printf "  %sCEK%s    %s\n" "$C_Y" "$C_N" "$1"; [ -n "$2" ] && printf "         %s\n" "$2"; warn=$((warn+1)); }
info()  { printf "  ...    %s\n" "$1"; }

hasil() {
  printf "\n  %sHasil:%s %d OK, %d GAGAL, %d CEK\n" "$C_B" "$C_N" "$ok" "$fail" "$warn"
  if [ "$fail" -eq 0 ]; then
    [ -n "$MANUAL_NOTE" ] && printf "  %s\n" "$MANUAL_NOTE"
    printf "  %sItem siap.%s\n\n" "$C_G" "$C_N"
  else
    printf "  %sBeresin yang GAGAL dulu, lalu jalanin cek ini lagi.%s\n\n" "$C_R" "$C_N"
  fi
  [ "$fail" -eq 0 ]
}
stop_here() { hasil; exit 1; }

# timeout ada di Linux, di Mac biasanya gtimeout (brew install coreutils).
if command -v timeout >/dev/null 2>&1; then TO="timeout"
elif command -v gtimeout >/dev/null 2>&1; then TO="gtimeout"
else TO=""; fi
run_to() { if [ -n "$TO" ]; then "$TO" "$@"; else shift; "$@"; fi; }

# Baca satu key dari exercise.yml (atau file lain). Buang komentar, spasi, dan tanda kutip.
yget() {
  local key="$1" def="$2" file="${3:-exercise.yml}" v=""
  [ -f "$file" ] && v="$(awk -v k="$key" '
    { line=$0; sub(/[[:space:]]+#.*$/, "", line) }
    line ~ "^"k":" { sub("^"k":[[:space:]]*", "", line); gsub(/^["'\'']|["'\'']$/, "", line); print line; exit }' "$file")"
  [ -n "$v" ] && printf '%s' "$v" || printf '%s' "$def"
}

# Cek isi exercise.yml yang berlaku buat semua format.
cek_exercise() {
  MODE="$(yget mode workshop)"; DIFF="$(yget difficulty easy)"; POINTS="$(yget points)"
  FLAG_PREFIX="$(yget flag_prefix flag)"
  case "$MODE" in workshop|probset) pass "Mode: $MODE" ;; *) gagal "mode '$MODE' nggak dikenal" "Isi mode: workshop atau probset" ;; esac
  case "$DIFF" in
    easy|medium) : ;;
    hard) [ "$MODE" = "probset" ] || gagal "Difficulty hard cuma buat mode probset" "Pakai easy atau medium buat workshop" ;;
    *) gagal "difficulty '$DIFF' nggak dikenal" "Isi easy, medium, atau hard" ;;
  esac
  if [ -n "$POINTS" ] && { [ "$DIFF" != "hard" ] || [ "$MODE" = "probset" ]; }; then
    local lo hi
    if [ "$MODE" = "workshop" ]; then
      case "$DIFF" in easy) lo=100; hi=100 ;; medium) lo=200; hi=200 ;; *) lo=0; hi=0 ;; esac
    else
      case "$DIFF" in easy) lo=50; hi=100 ;; medium) lo=150; hi=250 ;; hard) lo=300; hi=500 ;; *) lo=0; hi=0 ;; esac
    fi
    if printf '%s' "$POINTS" | grep -Eq '^[0-9]+$' && [ "$POINTS" -ge "$lo" ] && [ "$POINTS" -le "$hi" ]; then
      pass "Points $POINTS cocok buat $DIFF ($MODE)"
    else gagal "Points $POINTS nggak cocok buat $DIFF ($MODE)" "Range yang boleh: $lo sampai $hi"; fi
  fi
  if [ "$MODE" = "workshop" ] && [ "$FLAG_PREFIX" != "flag" ]; then
    gagal "Mode workshop harus pakai flag{...}" "Isi flag_prefix: flag"
  fi
}

# Baca dan cek satu file flag. Hasilnya di variabel FLAG.
cek_flag_file() {
  local f="${1:-flag.txt}"; FLAG=""
  if [ ! -f "$f" ]; then gagal "$f belum ada" "python3 -c \"import secrets; print('${FLAG_PREFIX}{' + secrets.token_hex(12) + '}')\" > $f"; return 1; fi
  FLAG="$(tr -d '\r\n[:space:]' < "$f")"
  if printf '%s' "$FLAG" | grep -Eq "^${FLAG_PREFIX}\{[^}]+\}$"; then pass "Format flag benar ($f)"
  else gagal "Isi $f bukan format ${FLAG_PREFIX}{...}" "Satu baris aja, contoh: ${FLAG_PREFIX}{3f9a1c...}"; return 1; fi
}

# Pastikan string flag nggak muncul di folder atau file yang dikasih.
cek_no_leak() {
  local what="$1"; shift
  local hit=""
  for p in "$@"; do
    [ -e "$p" ] || continue
    if grep -rnF "${FLAG_PREFIX}{" "$p" >/dev/null 2>&1 || { [ -n "$FLAG" ] && grep -rnF "$FLAG" "$p" >/dev/null 2>&1; }; then hit="$hit $p"; fi
  done
  if [ -z "$hit" ]; then pass "Flag nggak bocor di $what"
  else gagal "Flag bocor di:$hit" "grep -rn \"${FLAG_PREFIX}{\"$hit lalu pindahin flag ke file flag aja"; fi
}

cek_solver_no_peek() {  # peringatan aja. Bukti sebenarnya: solver dijalanin di folder kosong (run_solver).
  local f="${1:-solve.py}"
  if [ -f "$f" ] && grep -Eq "(open|Path|read_text)\([^)]*(flag\.txt|flags/|answer-key)" "$f"; then
    cek "$f kelihatan buka file flag lokal" "Solver harus ambil flag dari service atau dari file yang dikirim ke peserta"
  fi
  return 0
}

# run_solver DETIK ARG...: jalanin solve.py dari folder kosong, jadi nggak bisa ngintip flag lokal.
run_solver() {
  local secs="$1"; shift
  local T; T="$(mktemp -d)"; TMPS="$TMPS $T"
  cp solve.py "$T/"
  (cd "$T" && run_to "$secs" python3 solve.py "$@")
}

cek_files_exist() {
  local missing=""
  for f in "$@"; do [ -e "$f" ] || missing="$missing $f"; done
  if [ -z "$missing" ]; then pass "Item wajib ada ($#)"
  else gagal "Item belum ada:$missing" "Minta agent bikin item yang kurang, sesuai guide format-nya"; fi
}

cek_no_todo() {
  local hit="" ph=""
  for p in "$@"; do
    [ -e "$p" ] || continue
    grep -rlE 'TODO|GANTI_INI' "$p" >/dev/null 2>&1 && hit="$hit $p"
    grep -rlE '<\.\.\.>|<nama>|<[A-Z][a-z]+ [^<>]{3,}>' "$p" >/dev/null 2>&1 && ph="$ph $p"
  done
  if [ -z "$hit" ]; then pass "Nggak ada TODO yang ketinggalan"
  else cek "Masih ada TODO atau GANTI_INI di:$hit" "grep -rn -e TODO -e GANTI_INI$hit"; fi
  [ -n "$ph" ] && cek "Masih ada placeholder <...> di:$ph" "Isi bagian yang masih pakai kurung sudut"
  return 0
}

cek_base_image() {
  local df="${1:-Dockerfile}"
  [ -f "$df" ] || return 0
  if grep -Ei '^FROM[[:space:]]' "$df" | grep -Eqi ':latest|^FROM[[:space:]]+[^:[:space:]]+([[:space:]]|$)'; then
    cek "Base image di $df belum dipin versinya" "Pakai tag versi, contoh python:3.12-slim, jangan latest"
  else pass "Base image dipin versinya ($df)"; fi
}

cek_ips() {  # IP publik di file teks
  local out
  out="$(python3 "$CHECKS/json_checks.py" ips "$@" 2>&1)"
  if [ -z "$out" ]; then pass "IP cuma pakai range privat atau dokumentasi"
  else gagal "Ada IP publik: $(printf '%s' "$out" | head -3 | tr '\n' ' ')" "Pakai 10.x, 172.16-31.x, 192.168.x, atau 192.0.2.x, 198.51.100.x, 203.0.113.x"; fi
}

# Docker dan compose
docker_ready() {
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    gagal "Docker belum jalan" "Jalanin bash cek.sh dulu dan beresin bagian Docker"; stop_here
  fi
}

# Tiap compose yang dinyalain dicatat sebagai DIR::PROJECT, biar pasti dimatiin lagi di akhir.
STARTED=""
mark_started() { STARTED="$STARTED $PWD::${COMPOSE_PROJECT_NAME:-}"; }
cleanup_all() {
  local e d p
  for e in $STARTED; do
    d="${e%%::*}"; p="${e##*::}"
    (cd "$d" 2>/dev/null && if [ -n "$p" ]; then COMPOSE_PROJECT_NAME="$p" docker compose down -v --remove-orphans; else docker compose down -v --remove-orphans; fi) >/dev/null 2>&1
  done
  [ -n "$TMPS" ] && rm -rf $TMPS
}
trap cleanup_all EXIT INT TERM

# compose_checks <jumlah service> <port di dalam container...>
compose_checks() {
  local want="$1"; shift
  CFG="$(docker compose config 2>&1)"
  if [ $? -ne 0 ]; then gagal "docker-compose.yml nggak valid" "$(printf '%s' "$CFG" | tail -1)"; stop_here; fi
  local n; n="$(docker compose config --services 2>/dev/null | grep -c .)"
  SVC="$(docker compose config --services 2>/dev/null | head -1)"
  if [ "$n" = "$want" ]; then pass "Compose punya $n service ($SVC)"
  else gagal "Compose punya $n service" "Satu item satu container. Proses tambahan jalanin di container yang sama"; fi
  local unsafe=""
  printf '%s' "$CFG" | grep -q 'privileged: true' && unsafe="$unsafe privileged"
  printf '%s' "$CFG" | grep -q 'network_mode: host' && unsafe="$unsafe network_mode:host"
  printf '%s' "$CFG" | grep -q 'docker.sock' && unsafe="$unsafe docker.sock"
  printf '%s' "$CFG" | grep -q 'cap_add' && unsafe="$unsafe cap_add"
  printf '%s' "$CFG" | grep -q 'type: bind' && unsafe="$unsafe bind-mount"
  if [ -z "$unsafe" ]; then pass "Compose aman (nggak ada privileged, host network, socket, bind mount)"
  else gagal "Compose pakai:$unsafe" "Hapus dari docker-compose.yml, server lab nggak ngizinin itu"; fi
  for p in "$@"; do
    if printf '%s' "$CFG" | grep -Eq "target: \"?$p\"?"; then pass "Port $p di dalam container ada di compose"
    else gagal "Port $p di dalam container nggak ketemu di compose" "ports harus \"$p:$p\" dan service dengerin 0.0.0.0:$p"; fi
  done
}

compose_build_up() {
  info "build container, bisa makan waktu"
  local blog
  if blog="$(docker compose build 2>&1)"; then pass "Container ke-build"
  else
    gagal "Build gagal" "Lihat error di bawah, kasih ke agent buat dibenerin"
    printf '%s\n' "$blog" | grep -v '^[[:space:]]*$' | tail -12 | sed 's/^/         /'; stop_here
  fi
  local ulog
  if ulog="$(docker compose up -d 2>&1)"; then mark_started; pass "Container jalan"
  else gagal "docker compose up gagal" "$(printf '%s' "$ulog" | tail -1)"; stop_here; fi
}

host_port() {  # port di host buat port container $1
  local hp; hp="$(docker compose port "$SVC" "$1" 2>/dev/null | head -1 | awk -F: '{print $NF}')"
  printf '%s' "${hp:-$1}"
}

wait_http() {  # wait_http URL -> set HTTP_CODE, return 0 kalau jawab
  local i code
  for i in $(seq 1 30); do
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "$1/" 2>/dev/null)"
    case "$code" in 000|"") sleep 1 ;; *) HTTP_CODE="$code"; return 0 ;; esac
  done
  return 1
}

wait_tcp() {  # wait_tcp HOST PORT. Port yang di-publish Docker selalu nerima koneksi, jadi cek juga
  # koneksinya nggak langsung diputus (tanda service di dalam container belum siap).
  local i
  for i in $(seq 1 30); do
    python3 - "$1" "$2" <<'PY2' 2>/dev/null && return 0
import socket, sys
s = socket.create_connection((sys.argv[1], int(sys.argv[2])), timeout=2)
s.settimeout(1.0)
try:
    sys.exit(0 if s.recv(1) else 1)
except socket.timeout:
    sys.exit(0)
PY2
    sleep 1
  done
  return 1
}

show_logs() { docker compose logs --tail "${1:-15}" 2>/dev/null | sed 's/^/         /'; }

cek_request_log() {
  if docker compose logs 2>/dev/null | grep -Eq "${1:-\"?(GET|POST|PUT|DELETE|PATCH) /}"; then pass "Request kecatat di log"
  else cek "Request belum kecatat di log container" "Gunicorn: --access-logfile -. Express: morgan. socat: -d -d"; fi
}

json_results() {  # baca output json_checks.py, ubah jadi OK/GAGAL/CEK
  local kind msg hint
  while IFS=$'\t' read -r kind msg hint; do
    case "$kind" in OK) pass "$msg" ;; GAGAL) gagal "$msg" "$hint" ;; CEK) cek "$msg" "$hint" ;; esac
  done
}
