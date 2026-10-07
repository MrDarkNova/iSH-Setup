#!/bin/sh
set -u

NOVA_VERSION="1.0.3"
NOVA_REPO="MrDarkNova/iSH-Setup"
NOVA_SETUP_URL="https://raw.githubusercontent.com/${NOVA_REPO}/main/setup.sh"

HOME="${HOME:-/root}"
NOVA_DIR="$HOME/.nova"
NOVA_ETC="${NOVA_ETC:-/etc}"
LOG="${TMPDIR:-/tmp}/nova-setup.log"

LITE=0
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --lite) LITE=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)
      printf 'ɪSH-Sᴇᴛᴜᴘ %s\n  --lite       ꜱᴋɪᴘ ᴅᴇᴠ ᴛᴏᴏʟꜱ\n  --uninstall  ʀᴇᴍᴏᴠᴇ ᴛʜᴇ Nᴏᴠᴀ ʟᴏᴏᴋ\n' "$NOVA_VERSION"
      exit 0 ;;
  esac
done
[ "${NOVA_LITE:-0}" = "1" ] && LITE=1

if [ -t 1 ]; then
  V1=$(printf '\033[38;5;99m');  V2=$(printf '\033[38;5;141m'); V3=$(printf '\033[38;5;183m')
  GR=$(printf '\033[38;5;114m'); RD=$(printf '\033[38;5;203m'); YL=$(printf '\033[38;5;221m')
  DM=$(printf '\033[38;5;60m');  BD=$(printf '\033[1m');        RS=$(printf '\033[0m')
else
  V1=; V2=; V3=; GR=; RD=; YL=; DM=; BD=; RS=
fi

N=0
TOTAL=5
step() { N=$((N + 1)); printf '\n%s[%s/%s]%s %s%s%s\n' "$V2" "$N" "$TOTAL" "$RS" "$BD" "$1" "$RS"; }
ok()   { printf '  %s✔%s %s\n' "$GR" "$RS" "$1"; }
warn() { printf '  %s!%s %s\n' "$YL" "$RS" "$1"; }
fail() { printf '  %s✘%s %s\n' "$RD" "$RS" "$1"; }
die()  { fail "$1"; exit 1; }

splash() {
  printf '\n  %s╭──────────────────────────────╮%s\n' "$V1" "$RS"
  printf '  %s│%s  %s✦  ɪSH-Sᴇᴛᴜᴘ%s %s·%s ʙʏ DᴀʀᴋNᴏᴠᴀ  %s│%s\n' "$V1" "$RS" "$V3" "$RS" "$DM" "$RS" "$V1" "$RS"
  printf '  %s╰──────────────────────────────╯%s\n' "$V1" "$RS"
}

inject() {
  f=$1
  touch "$f"
  tmp="$f.nova.$$"
  sed '/# >>> nova-ish >>>/,/# <<< nova-ish <<</d' "$f" > "$tmp" && cat "$tmp" > "$f"
  rm -f "$tmp"
  cat >> "$f"
}

strip_block() {
  [ -f "$1" ] || return 0
  tmp="$1.nova.$$"
  sed '/# >>> nova-ish >>>/,/# <<< nova-ish <<</d' "$1" > "$tmp" && cat "$tmp" > "$1"
  rm -f "$tmp"
}

install_group() {
  label=$1; shift
  if apk add --no-cache "$@" >>"$LOG" 2>&1; then
    ok "$label"
    return 0
  fi
  good=""; bad=""
  for p in "$@"; do
    if apk add --no-cache "$p" >>"$LOG" 2>&1; then good="$good $p"; else bad="$bad $p"; fi
  done
  [ -n "$good" ] && ok "$label:$good"
  [ -n "$bad" ] && warn "ꜱᴋɪᴘᴘᴇᴅ:$bad  (ᴅᴇᴛᴀɪʟꜱ: $LOG)"
  return 0
}

run_banner() {
  if command -v timeout >/dev/null 2>&1 && timeout 1 true >/dev/null 2>&1; then
    { NOVA_TO=1 timeout 3 sh "$NOVA_DIR/banner.sh" </dev/null; } 2>/dev/null
  else
    NOVA_TO=0 sh "$NOVA_DIR/banner.sh" </dev/null
  fi
  return 0
}

if [ "$UNINSTALL" = "1" ]; then
  splash
  for f in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.inputrc" "$HOME/.nanorc"; do
    strip_block "$f"
  done
  rm -rf "$NOVA_DIR"
  printf '\n  %s✔%s Nᴏᴠᴀ ʟᴏᴏᴋ ʀᴇᴍᴏᴠᴇᴅ. Pᴀᴄᴋᴀɢᴇꜱ ᴡᴇʀᴇ ʟᴇꜰᴛ ɪɴ ᴘʟᴀᴄᴇ.\n' "$GR" "$RS"
  printf '  %sCʟᴏꜱᴇ ᴀɴᴅ ʀᴇᴏᴘᴇɴ ɪSH ᴛᴏ ɢᴇᴛ ʏᴏᴜʀ ᴏʟᴅ ᴘʀᴏᴍᴘᴛ ʙᴀᴄᴋ.%s\n\n' "$DM" "$RS"
  exit 0
fi

splash
: > "$LOG" 2>/dev/null || LOG=/dev/null
step "Cʜᴇᴄᴋɪɴɢ ᴇɴᴠɪʀᴏɴᴍᴇɴᴛ"
command -v apk >/dev/null 2>&1 || die "ᴀᴘᴋ ɴᴏᴛ ꜰᴏᴜɴᴅ. Tʜɪꜱ ꜱᴄʀɪᴘᴛ ɪꜱ ᴍᴀᴅᴇ ꜰᴏʀ ɪSH (Aʟᴘɪɴᴇ Lɪɴᴜx)."
ok "Aʟᴘɪɴᴇ ᴅᴇᴛᴇᴄᴛᴇᴅ"
[ -d /proc/ish ] && ok "ʀᴜɴɴɪɴɢ ɪɴꜱɪᴅᴇ ɪSH" || warn "ɪSH ɴᴏᴛ ᴅᴇᴛᴇᴄᴛᴇᴅ, ᴄᴏɴᴛɪɴᴜɪɴɢ ᴀɴʏᴡᴀʏ"

step "Uᴘᴅᴀᴛɪɴɢ ᴘᴀᴄᴋᴀɢᴇ ɪɴᴅᴇx"
if apk update >>"$LOG" 2>&1; then
  ok "ɪɴᴅᴇx ᴜᴘ ᴛᴏ ᴅᴀᴛᴇ"
else
  tail -n 4 "$LOG" 2>/dev/null
  die "ᴀᴘᴋ ᴜᴘᴅᴀᴛᴇ ꜰᴀɪʟᴇᴅ. Cʜᴇᴄᴋ ʏᴏᴜʀ ᴄᴏɴɴᴇᴄᴛɪᴏɴ ᴀɴᴅ ᴛʀʏ ᴀɢᴀɪɴ."
fi

step "Iɴꜱᴛᴀʟʟɪɴɢ ᴄᴏʀᴇ ᴛᴏᴏʟꜱ"
install_group "ᴄᴏʀᴇ" bash git curl wget ca-certificates ncurses nano tzdata jq

step "Iɴꜱᴛᴀʟʟɪɴɢ ᴅᴇᴠ ᴛᴏᴏʟꜱ"
if [ "$LITE" = "1" ]; then
  warn "ꜱᴋɪᴘᴘᴇᴅ (--lite)"
else
  install_group "ᴅᴇᴠ" nodejs npm python3 py3-pip openssh-client tmux htop
fi

step "Aᴘᴘʟʏɪɴɢ ᴛʜᴇ Nᴏᴠᴀ ʟᴏᴏᴋ"
mkdir -p "$NOVA_DIR" || die "ᴄᴀɴɴᴏᴛ ᴄʀᴇᴀᴛᴇ $NOVA_DIR"
rm -f "$NOVA_DIR/slow"

if [ ! -f "$NOVA_DIR/config" ]; then
  cat > "$NOVA_DIR/config" <<EOF
NOVA_NAME="${NOVA_NAME:-Victor}"
NOVA_TZ="${NOVA_TZ:-Africa/Lagos}"
NOVA_CITY="${NOVA_CITY:-Kaduna}"
NOVA_SITE="${NOVA_SITE:-mrdarknova.com}"
NOVA_GITHUB="${NOVA_GITHUB:-github.com/MrDarkNova}"
NOVA_SETUP_URL="$NOVA_SETUP_URL"
NOVA_BANNER="1"
EOF
fi
printf '%s\n' "$NOVA_VERSION" > "$NOVA_DIR/VERSION"

cat > "$NOVA_DIR/art.txt" <<'NOVA_ART'
 ___     _    ___  _  __
|   \   /_\  | _ \| |/ /
| |) | / _ \ |   /| ' <
|___/ /_/ \_\|_|_\|_|\_\
 _  _   ___  __   __   _
| \| | / _ \ \ \ / /  /_\
| .` || (_) | \ V /  / _ \
|_|\_| \___/   \_/  /_/ \_\
NOVA_ART

cat > "$NOVA_DIR/banner.sh" <<'NOVA_BANNER'
#!/bin/sh
NOVA_DIR="${NOVA_DIR:-$HOME/.nova}"
[ -f "$NOVA_DIR/config" ] && . "$NOVA_DIR/config"
: "${NOVA_NAME:=friend}" "${NOVA_SITE:=mrdarknova.com}" "${NOVA_GITHUB:=github.com/MrDarkNova}" "${NOVA_CITY:=Kaduna}"

HAS_TO="${NOVA_TO:-}"
if [ -z "$HAS_TO" ]; then
  if command -v timeout >/dev/null 2>&1 && timeout 1 true >/dev/null 2>&1; then HAS_TO=1; else HAS_TO=0; fi
fi

bounded() {
  if [ "$HAS_TO" = "1" ]; then timeout 2 "$@"; else "$@"; fi
}

if [ "${1:-}" = "--disk" ]; then
  out=$(bounded df -h / 2>/dev/null)
  printf '%s\n' "$out" | {
    read -r _
    read -r _ s u _
    if [ -n "$s" ] && [ -n "$u" ]; then printf 'disk %s/%s\n' "$u" "$s" > "$NOVA_DIR/disk"; fi
  }
  exit 0
fi

[ -n "${NOVA_TZ:-}" ] && export TZ="$NOVA_TZ"

E=$(printf '\033')
RS="${E}[0m"
BD="${E}[1m"
K60="${E}[38;5;60m"
K99="${E}[38;5;99m"
K141="${E}[38;5;141m"
K183="${E}[38;5;183m"
K219="${E}[38;5;219m"

sc() {
  SC=""
  _s=$1
  while [ -n "$_s" ]; do
    _r=${_s#?}
    _c=${_s%"$_r"}
    _s=$_r
    case $_c in
      a) _c=ᴀ ;;
      b) _c=ʙ ;;
      c) _c=ᴄ ;;
      d) _c=ᴅ ;;
      e) _c=ᴇ ;;
      f) _c=ꜰ ;;
      g) _c=ɢ ;;
      h) _c=ʜ ;;
      i) _c=ɪ ;;
      j) _c=ᴊ ;;
      k) _c=ᴋ ;;
      l) _c=ʟ ;;
      m) _c=ᴍ ;;
      n) _c=ɴ ;;
      o) _c=ᴏ ;;
      p) _c=ᴘ ;;
      q) _c=ǫ ;;
      r) _c=ʀ ;;
      s) _c=ꜱ ;;
      t) _c=ᴛ ;;
      u) _c=ᴜ ;;
      v) _c=ᴠ ;;
      w) _c=ᴡ ;;
      y) _c=ʏ ;;
      z) _c=ᴢ ;;
    esac
    SC=$SC$_c
  done
}

art() {
  if [ ! -r "$NOVA_DIR/art.txt" ]; then
    printf '  %sD A R K N O V A%s\n' "$K141" "$RS"
    return 0
  fi
  set -- 57 93 99 135 141 177 183 219
  while IFS= read -r line; do
    printf '  %s[38;5;%sm%s%s\n' "$E" "$1" "$line" "$RS"
    [ $# -gt 1 ] && shift
  done < "$NOVA_DIR/art.txt"
  return 0
}

row() { printf '  %s◆%s %s%s%s  %s\n' "$K141" "$RS" "$K60" "$1" "$RS" "$2"; }

join() {
  out=""
  for p in "$@"; do
    if [ -n "$p" ]; then
      if [ -n "$out" ]; then out="$out · "; fi
      out="$out$p"
    fi
  done
}

if [ "${1:-}" = "--art" ]; then art; exit 0; fi

SLOW=0
if [ -f "$NOVA_DIR/slow" ] && [ -n "$(find "$NOVA_DIR/slow" -mmin -60 2>/dev/null)" ]; then SLOW=1; fi

printf '\n'
art
printf '  %s──────────────────────────────%s\n' "$K60" "$RS"

d=""
if [ "$SLOW" = "0" ]; then
  d=$(bounded date '+%H|%S|%a %d %b · %H:%M' 2>/dev/null)
  if [ $? -ge 124 ]; then : > "$NOVA_DIR/slow"; SLOW=1; d=""; fi
fi
hr=${d%%|*}
rest=${d#*|}
sec=${rest%%|*}
dstr=${rest#*|}

case $hr in
  '')            greet="Hᴇʟʟᴏ" ;;
  0[0-4])        greet="Lᴀᴛᴇ-ɴɪɢʜᴛ ꜱᴇꜱꜱɪᴏɴ" ;;
  0[5-9]|1[01])  greet="Gᴏᴏᴅ ᴍᴏʀɴɪɴɢ" ;;
  1[2-6])        greet="Gᴏᴏᴅ ᴀꜰᴛᴇʀɴᴏᴏɴ" ;;
  *)             greet="Gᴏᴏᴅ ᴇᴠᴇɴɪɴɢ" ;;
esac

sc "$NOVA_NAME"; name=$SC
sc "$dstr"; dstrc=$SC
printf '  %s%s,%s %s%s%s %s✦%s\n' "$K183" "$greet" "$RS" "$BD" "$name" "$RS" "$K219" "$RS"
if [ -n "$dstr" ]; then printf '  %s%s%s\n' "$K60" "$dstrc" "$RS"; fi
printf '\n'

raw=""
if [ "$SLOW" = "0" ]; then
  raw=$(bounded cat /proc/uptime /proc/meminfo /etc/os-release 2>/dev/null)
  if [ $? -ge 124 ]; then : > "$NOVA_DIR/slow"; raw=""; fi
fi

secs=""; mt=""; ma=""; mf=""; osn=""; osv=""
while IFS= read -r line; do
  case $line in
    MemTotal:*)     set -- $line; mt=$2 ;;
    MemAvailable:*) set -- $line; ma=$2 ;;
    MemFree:*)      set -- $line; mf=$2 ;;
    NAME=*)         osn=${line#NAME=} ;;
    VERSION_ID=*)   osv=${line#VERSION_ID=} ;;
    [0-9]*)         if [ -z "$secs" ]; then secs=${line%%.*}; fi ;;
  esac
done <<EOF
$raw
EOF

up=""
case $secs in
  ''|*[!0-9]*) ;;
  *)
    dd=$((secs / 86400)); hh=$((secs % 86400 / 3600)); mm=$((secs % 3600 / 60))
    if [ "$dd" -gt 0 ]; then up="up ${dd}d ${hh}h"
    elif [ "$hh" -gt 0 ]; then up="up ${hh}h ${mm}m"
    else up="up ${mm}m"; fi ;;
esac

mem=""
[ -z "$ma" ] && ma=$mf
case $mt in ''|*[!0-9]*) mt="" ;; esac
case $ma in ''|*[!0-9]*) ma="" ;; esac
if [ -n "$mt" ] && [ -n "$ma" ] && [ "$mt" -gt 0 ]; then
  mem="$(( (mt - ma) / 1024 ))M/$(( mt / 1024 ))M"
fi

os=""
if [ -n "$osn" ]; then
  osn=${osn#\"}; osn=${osn%\"}
  osv=${osv#\"}; osv=${osv%\"}
  os="${osn}${osv:+ $osv}"
fi

disk=""
[ -r "$NOVA_DIR/disk" ] && read -r disk < "$NOVA_DIR/disk"

case $sec in [0-9][0-9]) ;; *) sec=00 ;; esac
case $(( 1$sec % 6 )) in
  0) tip="ᴜᴘᴅᴀᴛᴇ    ʀᴇꜰʀᴇꜱʜ ᴀʟʟ ᴘᴀᴄᴋᴀɢᴇꜱ" ;;
  1) tip="ꜱᴇʀᴠᴇ     ʜᴛᴛᴘ ꜱᴇʀᴠᴇʀ ᴏɴ :8000" ;;
  2) tip="ɢꜱ        ɢɪᴛ ꜱᴛᴀᴛᴜꜱ, ꜱʜᴏʀᴛ" ;;
  3) tip="ᴍʏɪᴘ      ꜱʜᴏᴡ ʏᴏᴜʀ ᴘᴜʙʟɪᴄ IP" ;;
  4) sc "$NOVA_CITY"; tip="ᴡᴇᴀᴛʜᴇʀ   ꜰᴏʀᴇᴄᴀꜱᴛ ꜰᴏʀ $SC" ;;
  *) tip="ɴᴏᴠᴀ      ꜱʜᴏᴡ ᴛʜɪꜱ ꜱᴄʀᴇᴇɴ ᴀɢᴀɪɴ" ;;
esac

join "$os" "$up"; sc "$out"; sys=$SC
join "$mem" "$disk"; sc "$out"; ram=$SC
sc "$NOVA_SITE"; site=$SC
sc "$NOVA_GITHUB"; gh=$SC

if [ -n "$sys" ]; then row "ꜱʏꜱ" "$sys"; fi
if [ -n "$ram" ]; then row "ʀᴀᴍ" "$ram"; fi
row "ᴡᴇʙ" "$site"
row "ɢɪᴛ" "$gh"
printf '\n  %sᴛɪᴘ ›%s %s%s%s\n\n' "$K99" "$RS" "$K183" "$tip" "$RS"

(sh "$NOVA_DIR/banner.sh" --disk </dev/null >/dev/null 2>&1 &)
exit 0
NOVA_BANNER

cat > "$NOVA_DIR/aliases.sh" <<'NOVA_ALIASES'
if ls --color=auto -d / >/dev/null 2>&1; then _nls='ls --color=auto'; else _nls='ls'; fi
alias ls="$_nls"
alias ll="$_nls -lAh"
alias la="$_nls -A"
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias update='apk update && apk upgrade'

alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -15'
alias gd='git diff'

alias serve='python3 -m http.server 8000'

mkcd()    { mkdir -p "$1" && cd "$1"; }
myip()    { curl -fsS https://ifconfig.me; echo; }
weather() { curl -fsS "https://wttr.in/${1:-${NOVA_CITY:-Kaduna}}?0"; }

__nova_show() {
  if [ -z "${__nova_to:-}" ]; then
    if command -v timeout >/dev/null 2>&1 && timeout 1 true >/dev/null 2>&1; then __nova_to=1; else __nova_to=0; fi
  fi
  if [ "$__nova_to" = "1" ]; then
    { NOVA_TO=1 timeout 3 sh "$HOME/.nova/banner.sh" </dev/null; } 2>/dev/null
  else
    NOVA_TO=0 sh "$HOME/.nova/banner.sh" </dev/null
  fi
  return 0
}

clear() {
  printf '\033[H\033[2J'
  if [ "${NOVA_BANNER:-1}" = "1" ]; then __nova_show; fi
  return 0
}

nova() {
  case "${1:-}" in
    update|up)  curl -fsSL "${NOVA_SETUP_URL:-https://raw.githubusercontent.com/MrDarkNova/iSH-Setup/main/setup.sh}" | sh ;;
    config)     "${EDITOR:-nano}" "$HOME/.nova/config" ;;
    uninstall)  curl -fsSL "${NOVA_SETUP_URL:-https://raw.githubusercontent.com/MrDarkNova/iSH-Setup/main/setup.sh}" | sh -s -- --uninstall ;;
    help|-h|--help)
      printf 'nova            ꜱʜᴏᴡ ᴛʜᴇ ʙᴀɴɴᴇʀ\n'
      printf 'nova update     ʀᴇ-ʀᴜɴ ᴛʜᴇ ɪɴꜱᴛᴀʟʟᴇʀ\n'
      printf 'nova config     ᴇᴅɪᴛ ɴᴀᴍᴇ / ᴛɪᴍᴇᴢᴏɴᴇ / ʟɪɴᴋꜱ\n'
      printf 'nova uninstall  ʀᴇᴍᴏᴠᴇ ᴛʜᴇ Nᴏᴠᴀ ʟᴏᴏᴋ\n' ;;
    *)          __nova_show ;;
  esac
}
NOVA_ALIASES

cat > "$NOVA_DIR/prompt.sh" <<'NOVA_PROMPT'
HISTSIZE=5000
HISTFILESIZE=10000
HISTCONTROL=ignoredups:erasedups
PROMPT_DIRTRIM=3
shopt -s histappend checkwinsize cmdhist 2>/dev/null

__nova_branch() {
  __nova_br=""
  local d=$PWD h
  while [ -n "$d" ]; do
    if [ -f "$d/.git/HEAD" ]; then
      read -r h < "$d/.git/HEAD"
      case $h in
        "ref: refs/heads/"*) __nova_br=${h#ref: refs/heads/} ;;
        *) __nova_br=${h:0:7} ;;
      esac
      return
    fi
    d=${d%/*}
  done
}

__nova_prompt() {
  local ec=$?
  history -a 2>/dev/null
  __nova_branch
  local v1='\[\e[38;5;99m\]' v2='\[\e[38;5;141m\]' v3='\[\e[38;5;183m\]'
  local dm='\[\e[38;5;60m\]' rd='\[\e[38;5;203m\]' rs='\[\e[0m\]'
  local mark="$v3" br="" ex=""
  [ -n "$__nova_br" ] && br="${dm}─[${v3}⎇ ${__nova_br}${dm}]"
  if [ "$ec" -ne 0 ]; then mark="$rd"; ex="${dm}─[${rd}✘ ${ec}${dm}]"; fi
  PS1="\n${dm}╭─[${v1}ɴᴏᴠᴀ${dm}]─[${v2}\w${dm}]${br}${ex}${rs}\n${dm}╰─${mark}❯${rs} "
}
PROMPT_COMMAND=__nova_prompt
NOVA_PROMPT

inject "$HOME/.bashrc" <<'NOVA_RC'
# >>> nova-ish >>>
case $- in
  *i*)
    [ -f "$HOME/.nova/config" ] && . "$HOME/.nova/config"
    export TERM="${TERM:-xterm-256color}"
    [ -n "${NOVA_TZ:-}" ] && export TZ="$NOVA_TZ"
    export EDITOR="${EDITOR:-nano}"
    [ -f "$HOME/.nova/aliases.sh" ] && . "$HOME/.nova/aliases.sh"
    [ -f "$HOME/.nova/prompt.sh" ] && . "$HOME/.nova/prompt.sh"
    if [ -z "${NOVA_SHOWN:-}" ]; then
      export NOVA_SHOWN=1
      if [ -t 1 ]; then clear; fi
    fi
    ;;
esac
# <<< nova-ish <<<
NOVA_RC

inject "$HOME/.bash_profile" <<'NOVA_BP'
# >>> nova-ish >>>
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
# <<< nova-ish <<<
NOVA_BP

inject "$HOME/.profile" <<'NOVA_PROFILE'
# >>> nova-ish >>>
if [ -z "${BASH_VERSION:-}" ] && [ -x /bin/bash ] && [ -t 0 ]; then
  exec /bin/bash -l
fi
# <<< nova-ish <<<
NOVA_PROFILE

inject "$HOME/.inputrc" <<'NOVA_INPUTRC'
# >>> nova-ish >>>
set completion-ignore-case on
set show-all-if-ambiguous on
set colored-stats on
set colored-completion-prefix on
# <<< nova-ish <<<
NOVA_INPUTRC

inject "$HOME/.nanorc" <<'NOVA_NANORC'
# >>> nova-ish >>>
set linenumbers
set tabsize 2
set tabstospaces
set autoindent
include "/usr/share/nano/*.nanorc"
# <<< nova-ish <<<
NOVA_NANORC
ok "ʙᴀɴɴᴇʀ, ᴘʀᴏᴍᴘᴛ, ᴀʟɪᴀꜱᴇꜱ ᴀɴᴅ ᴄᴏɴꜰɪɢ ɪɴꜱᴛᴀʟʟᴇᴅ"

if [ -w "$NOVA_ETC/motd" ] || [ ! -e "$NOVA_ETC/motd" ]; then
  : > "$NOVA_ETC/motd" 2>/dev/null && ok "ᴅᴇꜰᴀᴜʟᴛ ᴡᴇʟᴄᴏᴍᴇ ᴍᴇꜱꜱᴀɢᴇ ᴄʟᴇᴀʀᴇᴅ"
fi

if command -v git >/dev/null 2>&1; then
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global core.editor nano
  git config --global color.ui auto
  ok "ɢɪᴛ ᴅᴇꜰᴀᴜʟᴛꜱ ꜱᴇᴛ"
fi

run_banner
printf '  %s✔ Aʟʟ ꜱᴇᴛ.%s Cʟᴏꜱᴇ ᴀɴᴅ ʀᴇᴏᴘᴇɴ ɪSH, ᴏʀ ʀᴜɴ: %sexec bash -l%s\n' "$GR" "$RS" "$V3" "$RS"
if command -v git >/dev/null 2>&1 && [ -z "$(git config --global user.name 2>/dev/null)" ]; then
  printf '  %sɢɪᴛ ɪᴅᴇɴᴛɪᴛʏ ɴᴏᴛ ꜱᴇᴛ ʏᴇᴛ:%s\n' "$DM" "$RS"
  printf '    git config --global user.name "Your Name"\n'
  printf '    git config --global user.email "you@example.com"\n'
fi
printf '\n'
