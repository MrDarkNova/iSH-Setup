#!/bin/sh
# ──────────────────────────────────────────────────────────────
#  iSH-Setup  ·  a cool-looking iSH, one paste
#  by Victor Kumba (DarkNova)  ·  https://mrdarknova.com
#
#  Install:
#    apk add --no-cache curl ca-certificates && \
#    curl -fsSL https://raw.githubusercontent.com/MrDarkNova/iSH-Setup/main/setup.sh | sh
#
#  Flags (append after `sh -s --`):
#    --lite        skip dev tools (node, python, ssh, tmux, htop)
#    --uninstall   remove the Nova look (packages are left alone)
# ──────────────────────────────────────────────────────────────
set -u

NOVA_VERSION="1.0.0"
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
      printf 'iSH-Setup %s\n  --lite       skip dev tools\n  --uninstall  remove the Nova look\n' "$NOVA_VERSION"
      exit 0 ;;
  esac
done
[ "${NOVA_LITE:-0}" = "1" ] && LITE=1

# ── colours (only when stdout is a terminal) ──────────────────
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
  printf '  %s│%s  %s✦  iSH-Setup%s %s·%s by DarkNova  %s│%s\n' "$V1" "$RS" "$V3" "$RS" "$DM" "$RS" "$V1" "$RS"
  printf '  %s╰──────────────────────────────╯%s\n' "$V1" "$RS"
}

# Replace (or add) a marked block in a file, reading the new block from stdin.
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
  [ -n "$bad" ] && warn "skipped:$bad  (details: $LOG)"
  return 0
}

# ── uninstall ─────────────────────────────────────────────────
if [ "$UNINSTALL" = "1" ]; then
  splash
  for f in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.inputrc" "$HOME/.nanorc"; do
    strip_block "$f"
  done
  rm -rf "$NOVA_DIR"
  printf '\n  %s✔%s Nova look removed. Packages were left in place.\n' "$GR" "$RS"
  printf '  %sClose and reopen iSH to get your old prompt back.%s\n\n' "$DM" "$RS"
  exit 0
fi

# ── 1. preflight ──────────────────────────────────────────────
splash
: > "$LOG" 2>/dev/null || LOG=/dev/null
step "Checking environment"
command -v apk >/dev/null 2>&1 || die "apk not found. This script is made for iSH (Alpine Linux)."
ok "Alpine detected"
[ -d /proc/ish ] && ok "running inside iSH" || warn "iSH not detected, continuing anyway"

# ── 2. package index ──────────────────────────────────────────
step "Updating package index"
if apk update >>"$LOG" 2>&1; then
  ok "index up to date"
else
  tail -n 4 "$LOG" 2>/dev/null
  die "apk update failed. Check your connection and try again."
fi

# ── 3. core tools ─────────────────────────────────────────────
step "Installing core tools"
install_group "core" bash git curl wget ca-certificates ncurses nano tzdata jq

# ── 4. dev tools ──────────────────────────────────────────────
step "Installing dev tools"
if [ "$LITE" = "1" ]; then
  warn "skipped (--lite)"
else
  install_group "dev" nodejs npm python3 py3-pip openssh-client tmux htop
fi

# ── 5. the Nova look ──────────────────────────────────────────
step "Applying the Nova look"
mkdir -p "$NOVA_DIR" || die "cannot create $NOVA_DIR"

# --- config (kept if it already exists, so your edits survive updates)
if [ ! -f "$NOVA_DIR/config" ]; then
  cat > "$NOVA_DIR/config" <<EOF
# Nova settings. Edit freely; run \`nova config\` to open this file.
NOVA_NAME="${NOVA_NAME:-Victor}"
NOVA_TZ="${NOVA_TZ:-Africa/Lagos}"
NOVA_CITY="${NOVA_CITY:-Kaduna}"
NOVA_SITE="${NOVA_SITE:-mrdarknova.com}"
NOVA_GITHUB="${NOVA_GITHUB:-github.com/MrDarkNova}"
NOVA_SETUP_URL="$NOVA_SETUP_URL"
EOF
fi
printf '%s\n' "$NOVA_VERSION" > "$NOVA_DIR/VERSION"

# --- ASCII art (swap this file for your own, up to ~38 columns wide)
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

# --- banner (plain POSIX sh, no dependencies)
cat > "$NOVA_DIR/banner.sh" <<'NOVA_BANNER'
#!/bin/sh
# Nova banner: shown when iSH opens. `nova` runs it again.
NOVA_DIR="${NOVA_DIR:-$HOME/.nova}"
[ -f "$NOVA_DIR/config" ] && . "$NOVA_DIR/config"
: "${NOVA_NAME:=friend}" "${NOVA_SITE:=mrdarknova.com}" "${NOVA_GITHUB:=github.com/MrDarkNova}"
[ -n "${NOVA_TZ:-}" ] && export TZ="$NOVA_TZ"

E=$(printf '\033')
RS="${E}[0m"; BD="${E}[1m"
col() { printf '%s[38;5;%sm' "$E" "$1"; }
nap() { [ "${NOVA_FAST:-0}" = "1" ] || sleep 0.03 2>/dev/null || :; }

art() {
  if [ ! -r "$NOVA_DIR/art.txt" ]; then
    printf '  %sD A R K N O V A%s\n' "$(col 141)" "$RS"
    return
  fi
  set -- 57 93 99 135 141 177 183 219
  while IFS= read -r line; do
    printf '  %s%s%s\n' "$(col "$1")" "$line" "$RS"
    [ $# -gt 1 ] && shift
    nap
  done < "$NOVA_DIR/art.txt"
}

row() { printf '  %s◆%s %s%-4s%s %s\n' "$(col 141)" "$RS" "$(col 60)" "$1" "$RS" "$2"; nap; }

if [ "${1:-}" = "--art" ]; then art; exit 0; fi

# greeting by hour
hr=$(date +%H 2>/dev/null)
case $hr in
  0[0-4])        greet="Late-night session" ;;
  0[5-9]|1[01])  greet="Good morning" ;;
  1[2-6])        greet="Good afternoon" ;;
  *)             greet="Good evening" ;;
esac

# system facts (every one of these is optional)
os=""
if [ -r /etc/os-release ]; then
  os=$(. /etc/os-release 2>/dev/null; printf '%s %s' "${NAME:-Linux}" "${VERSION_ID:-}")
fi
up=""
if [ -r /proc/uptime ]; then
  read -r secs _ < /proc/uptime
  secs=${secs%%.*}
  case $secs in
    ''|*[!0-9]*) ;;
    *)
      dd=$((secs / 86400)); hh=$((secs % 86400 / 3600)); mm=$((secs % 3600 / 60))
      if [ "$dd" -gt 0 ]; then up="up ${dd}d ${hh}h"
      elif [ "$hh" -gt 0 ]; then up="up ${hh}h ${mm}m"
      else up="up ${mm}m"; fi ;;
  esac
fi
mem=""
if [ -r /proc/meminfo ]; then
  mem=$(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} /^MemFree:/{f=$2} END{if(a=="")a=f; if(t>0) printf "%dM/%dM", (t-a)/1024, t/1024}' /proc/meminfo 2>/dev/null)
fi
disk=$(df -h / 2>/dev/null | awk 'NR==2 && $2!="" {print "disk " $3 "/" $2}')

join() { out=""; for p in "$@"; do [ -n "$p" ] && { [ -n "$out" ] && out="$out · "; out="$out$p"; }; done; printf '%s' "$out"; }

case $(( 1$(date +%S 2>/dev/null || echo 00) % 6 )) in
  0) tip="update    refresh all packages" ;;
  1) tip="serve     http server on :8000" ;;
  2) tip="gs        git status, short" ;;
  3) tip="myip      show your public IP" ;;
  4) tip="weather   forecast for $NOVA_CITY" ;;
  *) tip="nova      show this screen again" ;;
esac

printf '\n'
art
printf '  %s──────────────────────────────%s\n' "$(col 60)" "$RS"
printf '  %s%s,%s %s%s%s %s✦%s\n' "$(col 183)" "$greet" "$RS" "$BD" "$NOVA_NAME" "$RS" "$(col 219)" "$RS"
printf '  %s%s%s\n\n' "$(col 60)" "$(date '+%a %d %b · %H:%M' 2>/dev/null)" "$RS"
sys=$(join "$os" "$up")
ram=$(join "$mem" "$disk")
[ -n "$sys" ] && row sys "$sys"
[ -n "$ram" ] && row ram "$ram"
row web "$NOVA_SITE"
row git "$NOVA_GITHUB"
printf '\n  %stip ›%s %s%s%s\n\n' "$(col 99)" "$RS" "$(col 183)" "$tip" "$RS"
NOVA_BANNER

# --- aliases + helpers
cat > "$NOVA_DIR/aliases.sh" <<'NOVA_ALIASES'
# Nova aliases: safe for bash and ash
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

nova() {
  case "${1:-}" in
    update|up)  curl -fsSL "${NOVA_SETUP_URL:-https://raw.githubusercontent.com/MrDarkNova/iSH-Setup/main/setup.sh}" | sh ;;
    config)     "${EDITOR:-nano}" "$HOME/.nova/config" ;;
    uninstall)  curl -fsSL "${NOVA_SETUP_URL:-https://raw.githubusercontent.com/MrDarkNova/iSH-Setup/main/setup.sh}" | sh -s -- --uninstall ;;
    help|-h|--help)
      printf 'nova            show the banner\n'
      printf 'nova update     re-run the installer\n'
      printf 'nova config     edit name / timezone / links\n'
      printf 'nova uninstall  remove the Nova look\n' ;;
    *)          sh "$HOME/.nova/banner.sh" ;;
  esac
}
NOVA_ALIASES

# --- prompt (bash)
cat > "$NOVA_DIR/prompt.sh" <<'NOVA_PROMPT'
# Nova prompt: two lines, git branch without forking git, red on failure
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
  PS1="\n${dm}╭─[${v1}nova${dm}]─[${v2}\w${dm}]${br}${ex}${rs}\n${dm}╰─${mark}❯${rs} "
}
PROMPT_COMMAND=__nova_prompt
NOVA_PROMPT

# --- hook it all into the shell startup files
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
      [ -t 1 ] && printf '\033[H\033[2J'
      sh "$HOME/.nova/banner.sh"
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

# iSH logs in with ash, so hand over to bash when it is installed
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
ok "banner, prompt, aliases and config installed"

# clean login: drop the stock welcome text
if [ -w "$NOVA_ETC/motd" ] || [ ! -e "$NOVA_ETC/motd" ]; then
  : > "$NOVA_ETC/motd" 2>/dev/null && ok "default welcome message cleared"
fi

# sensible git defaults (never touches your name or email)
if command -v git >/dev/null 2>&1; then
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global core.editor nano
  git config --global color.ui auto
  ok "git defaults set"
fi

# ── done ──────────────────────────────────────────────────────
NOVA_FAST="${NOVA_FAST:-0}" sh "$NOVA_DIR/banner.sh"
printf '  %s✔ All set.%s Close and reopen iSH, or run: %sexec bash -l%s\n' "$GR" "$RS" "$V3" "$RS"
if command -v git >/dev/null 2>&1 && [ -z "$(git config --global user.name 2>/dev/null)" ]; then
  printf '  %sgit identity not set yet:%s\n' "$DM" "$RS"
  printf '    git config --global user.name "Your Name"\n'
  printf '    git config --global user.email "you@example.com"\n'
fi
printf '\n'
