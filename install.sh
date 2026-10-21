#!/usr/bin/env bash
# install.sh — link claude-restore and claude-provider into ~/.local/bin.
#
#   ./install.sh           # symlink both scripts (re-run any time; idempotent)
#   ./install.sh --cron    # also add the 10-minute snapshot entry to your crontab
#
# Symlinks mean a `git pull` in this checkout updates the installed commands.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin"
DEST="${PREFIX:-$HOME/.local/bin}"
CRON=0
for a in "$@"; do
  case "$a" in
    --cron) CRON=1 ;;
    -h|--help) awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

missing=()
for c in tmux python3 claude; do command -v "$c" >/dev/null || missing+=("$c"); done
[ "${#missing[@]}" -eq 0 ] || echo "Warning: not on PATH: ${missing[*]}" >&2
[ "$(uname -s)" = Linux ] || echo "Warning: these scripts read /proc and only run on Linux." >&2

mkdir -p "$DEST"
for f in claude-restore claude-provider; do
  if [ -e "$DEST/$f" ] && [ ! -L "$DEST/$f" ]; then
    echo "Skipping $DEST/$f: a regular file is already there. Move it aside and re-run." >&2
    continue
  fi
  ln -sfn "$SRC/$f" "$DEST/$f"
  echo "Linked $DEST/$f -> $SRC/$f"
done

case ":$PATH:" in *":$DEST:"*) ;; *) echo "Note: $DEST is not on your PATH." >&2 ;; esac

if [ "$CRON" = 1 ]; then
  line="*/10 * * * * $DEST/claude-restore --save >/dev/null 2>&1"
  { crontab -l 2>/dev/null | grep -vF 'claude-restore --save' || true; echo "$line"; } | crontab -
  echo "Cron: $line"
fi

cat <<'EOF'

Suggested aliases (add to ~/.bashrc or ~/.bash_aliases):
  alias cr='claude-restore'
  alias crl='claude-restore --list'
  alias crs='claude-restore --save'
  alias crr='claude-restore --restart'
  alias cpv='claude-provider'

Using Amazon Bedrock? Save your own API key with:  claude-provider key
EOF
