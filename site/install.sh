#!/bin/sh
# colincode installer — https://colincode.org
#   curl -fsSL https://colincode.org/install.sh | sh
#
# Installs the `colin` command into ~/.local/bin (override with COLIN_BIN_DIR).
# `colin` is a single bash script; it needs the Luxor CLI and jq at runtime.
set -eu

BASE="${COLIN_BASE_URL:-https://colincode.org}"
BIN_DIR="${COLIN_BIN_DIR:-$HOME/.local/bin}"
DEST="$BIN_DIR/colin"

say()  { printf '\033[2m==>\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[33m warn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v bash >/dev/null 2>&1 || die "bash is required (colin is a bash script)"

mkdir -p "$BIN_DIR"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

say "downloading colin from $BASE/colin"
curl -fsSL "$BASE/colin" -o "$tmp" || die "download failed"
head -n1 "$tmp" | grep -q 'bash' || die "downloaded file does not look like the colin script"
bash -n "$tmp" || die "downloaded script failed a syntax check"

install -m 0755 "$tmp" "$DEST"
say "installed $DEST"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) warn "$BIN_DIR is not on your PATH. Add this to your shell profile:"
     printf '\n    export PATH="%s:$PATH"\n\n' "$BIN_DIR" >&2 ;;
esac

missing=""
command -v tenki >/dev/null 2>&1 || missing="$missing Luxor"
command -v jq    >/dev/null 2>&1 || missing="$missing jq"
if [ -n "$missing" ]; then
  warn "colin needs these at runtime and they were not found:$missing"
  case "$missing" in *Luxor*) warn "  Luxor CLI: https://tenki.cloud/docs/cli" ;; esac
  case "$missing" in *jq*)    warn "  jq: brew install jq  |  apt-get install jq" ;; esac
fi

printf '\n  Next:\n' >&2
printf '    tenki login          # once, if you have not already\n' >&2
printf '    colin                # pick a harness and provider, name your agent\n' >&2
printf '    colin claude         # or go straight to Claude Code\n\n' >&2
