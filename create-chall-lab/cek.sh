#!/usr/bin/env bash
# cek.sh: cek kesiapan laptop buat Workshop Cyber Drill Builder
# Jalanin:  bash ~/probset-skills/create-chall-lab/cek.sh   (repo: https://github.com/mqusaeri/probset-skills)
# Di venue, sekalian cek CTFd:  CTFD_URL=http://<alamat-ctfd> bash cek.sh
# Harness dideteksi otomatis. Kalau kepasang lebih dari satu:  HARNESS=claude bash cek.sh
#   (pilihan: hermes, openclaw, claude, codex, opencode)

# Isi sesuai info fasilitator sebelum dibagiin
TOKEN_VAR="${TOKEN_VAR:-}"                       # opsional, cara pasang token dari fasilitator
SKILL="${SKILL:-create-chall-lab}"               # [nama skill]
HARNESS="${HARNESS:-}"
PORT="${PORT:-8080}"                             # [PORT]
CTFD_URL="${CTFD_URL:-}"                         # [alamat CTFd], boleh kosong kalau belum di venue

ok=0; fail=0; warn=0
if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; N=$'\033[0m'; else G=; R=; Y=; B=; N=; fi
pass()  { printf "  %sOK%s     %s\n" "$G" "$N" "$1"; ok=$((ok+1)); }
gagal() { printf "  %sGAGAL%s  %s\n" "$R" "$N" "$1"; [ -n "$2" ] && printf "         Coba: %s\n" "$2"; fail=$((fail+1)); }
cek()   { printf "  %sCEK%s    %s\n" "$Y" "$N" "$1"; [ -n "$2" ] && printf "         %s\n" "$2"; warn=$((warn+1)); }

printf "\n%sCek laptop buat Workshop Cyber Drill Builder%s\n\n" "$B" "$N"

os="$(uname -s)"; arch="$(uname -m)"
if grep -qi microsoft /proc/version 2>/dev/null; then sys="Windows (WSL)"
elif [ "$os" = "Darwin" ]; then sys="Mac"
else sys="Linux"; fi
printf "  Sistem: %s, %s\n\n" "$sys" "$arch"

# Harness: pakai HARNESS kalau diisi, kalau nggak ambil yang pertama ketemu
if [ -z "$HARNESS" ]; then
  for h in hermes openclaw claude codex opencode; do
    if command -v "$h" >/dev/null 2>&1; then HARNESS="$h"; break; fi
  done
fi
case "$HARNESS" in
  hermes)   SKDIR="$HOME/.hermes/skills" ;;
  openclaw) SKDIR="$HOME/.openclaw/skills" ;;
  claude)   SKDIR="$HOME/.claude/skills" ;;
  codex)    SKDIR="$HOME/.agents/skills" ;;
  opencode) SKDIR="$HOME/.config/opencode/skills" ;;
  "")       SKDIR="" ;;
  *)        printf "  HARNESS=%s nggak dikenal. Pilihan: hermes, openclaw, claude, codex, opencode\n\n" "$HARNESS"; HARNESS=""; SKDIR="" ;;
esac

# Mac Intel nggak didukung Hermes
if [ "$HARNESS" = "hermes" ] && [ "$sys" = "Mac" ] && [ "$arch" != "arm64" ]; then
  gagal "Mac Intel terdeteksi" "Hermes cuma jalan di Mac Apple Silicon. Pilih harness lain di panduan bagian 0."
fi

# Di WSL, kerja harus di folder Linux
if [ "$sys" = "Windows (WSL)" ]; then
  case "$PWD" in
    /mnt/*) gagal "Folder kerja ada di drive Windows ($PWD)" "cd ~ lalu clone ulang repo di sana" ;;
    *)      pass "Folder kerja ada di dalam WSL" ;;
  esac
fi

# git
if command -v git >/dev/null 2>&1; then pass "git $(git --version | awk '{print $3}')"
else gagal "git belum ada" "Windows: sudo apt install -y git. Mac: xcode-select --install"; fi

# python3 buat solver
if command -v python3 >/dev/null 2>&1; then pass "python3 $(python3 --version 2>&1 | awk '{print $2}')"
else gagal "python3 belum ada" "Windows: sudo apt install -y python3. Mac: xcode-select --install"; fi

# curl
if command -v curl >/dev/null 2>&1; then pass "curl ada"
else gagal "curl belum ada" "Windows: sudo apt install -y curl"; fi

# Docker Engine (gratis). Windows: di Ubuntu WSL. Mac: lewat Colima. Docker Desktop nggak dipakai.
if [ "$sys" = "Mac" ]; then
  h_install="brew install colima docker docker-compose docker-buildx, lalu colima start (panduan bagian 0)"
  h_start="colima start"
  h_perm="colima restart"
  h_compose="Cek ~/.docker/config.json sesuai panduan bagian 0, atau brew install docker-compose"
else
  h_install="curl -fsSL https://get.docker.com | sudo sh, lalu sudo usermod -aG docker \$USER (panduan bagian 0)"
  h_start="sudo service docker start"
  if [ "$sys" = "Windows (WSL)" ]; then
    h_perm="sudo usermod -aG docker \$USER, lalu di PowerShell: wsl --shutdown, terus buka Ubuntu lagi"
  else
    h_perm="sudo usermod -aG docker \$USER, lalu logout dan login lagi"
  fi
  h_compose="sudo apt install -y docker-compose-plugin, atau docker-compose-v2 kalau Docker dari paket Ubuntu"
fi
if ! command -v docker >/dev/null 2>&1; then
  gagal "docker belum ada" "$h_install"
else
  dinfo="$(docker info 2>&1)"; drc=$?
  if [ $drc -ne 0 ] && printf '%s' "$dinfo" | grep -qi 'permission denied'; then
    gagal "User kamu belum boleh pakai Docker" "$h_perm"
  elif [ $drc -ne 0 ]; then
    gagal "Docker belum jalan" "$h_start"
  else
    pass "Docker jalan"
    if docker compose version >/dev/null 2>&1; then pass "docker compose ada"
    else gagal "docker compose belum ada" "$h_compose"; fi
    if docker run --rm hello-world >/dev/null 2>&1; then pass "Bisa download dan jalanin container"
    else gagal "Container test gagal jalan" "Cek internet atau proxy, lalu jalanin: docker run --rm hello-world"; fi
  fi
fi

# Harness dan skill
if [ -z "$HARNESS" ]; then
  gagal "Harness belum ada" "Install salah satu: hermes, openclaw, claude, codex, atau opencode (panduan bagian 0), lalu buka terminal baru"
elif ! command -v "$HARNESS" >/dev/null 2>&1; then
  gagal "$HARNESS belum ada" "Install dulu sesuai panduan bagian 0, lalu buka terminal baru"
else
  pass "Harness: $HARNESS"
  if [ -f "$SKDIR/$SKILL/SKILL.md" ]; then pass "Skill $SKILL kepasang"
  else sk="${SKDIR/#$HOME/~}"; gagal "Skill $SKILL belum kepasang" "mkdir -p $sk && cp -r ~/probset-skills/$SKILL $sk/"; fi
  if [ "$HARNESS" = "codex" ] && [ "$sys" != "Mac" ] && ! command -v bwrap >/dev/null 2>&1; then
    gagal "bubblewrap belum ada" "sudo apt install -y bubblewrap"
  fi
fi

# Token. Cuma CEK, karena token dibagiin di venue
tok=1
if [ -n "$TOKEN_VAR" ] && [ -n "${!TOKEN_VAR}" ]; then tok=0
else
  case "$HARNESS" in
    hermes)   grep -qsE '^[A-Z_]*(KEY|TOKEN)=.+' ~/.hermes/.env && tok=0 ;;
    openclaw) [ -n "${ANTHROPIC_API_KEY}${OPENAI_API_KEY}" ] || grep -qsE '^[A-Z_]*(KEY|TOKEN)=.+' ~/.openclaw/.env || [ -s ~/.openclaw/openclaw.json ] && tok=0 ;;
    claude)   [ -n "${ANTHROPIC_API_KEY}${ANTHROPIC_AUTH_TOKEN}" ] || grep -qs 'ANTHROPIC_AUTH_TOKEN\|ANTHROPIC_API_KEY' ~/.claude/settings.json || claude auth status >/dev/null 2>&1 && tok=0 ;;
    codex)    codex login status >/dev/null 2>&1 && tok=0 ;;
    opencode) [ -s ~/.local/share/opencode/auth.json ] || grep -qs '"provider"' ~/.config/opencode/opencode.json && tok=0 ;;
  esac
fi
if [ $tok -eq 0 ]; then pass "Token kepasang"
else cek "Token belum kepasang" "Wajar kalau belum di venue. Token dibagiin fasilitator."; fi

# Port soal
if (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; then
  cek "Port $PORT lagi dipakai aplikasi lain" "Matiin aplikasinya, atau tanya fasilitator port pengganti"
else pass "Port $PORT kosong"; fi

# Disk
free_gb=$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2 {printf "%d", $4/1048576}')
if [ "${free_gb:-0}" -ge 15 ]; then pass "Disk kosong ${free_gb} GB"
else cek "Disk kosong cuma ${free_gb:-?} GB" "Sisain minimal 15 GB buat image Docker"; fi

# CTFd, cuma kalau alamatnya diisi
if [ -n "$CTFD_URL" ]; then
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$CTFD_URL")
  case "$code" in
    2*|3*) pass "CTFd kebuka di $CTFD_URL" ;;
    *)     gagal "CTFd nggak kebuka di $CTFD_URL" "Cek internet laptop, lalu cocokin alamat CTFd ke fasilitator" ;;
  esac
fi

printf "\n  %sHasil:%s %d OK, %d GAGAL, %d CEK\n" "$B" "$N" "$ok" "$fail" "$warn"
if [ "$fail" -eq 0 ]; then printf "  %sLaptop siap.%s\n\n" "$G" "$N"
else printf "  %sBeresin yang GAGAL dulu, atau kirim hasil ini ke fasilitator.%s\n\n" "$R" "$N"; fi
[ "$fail" -eq 0 ]
