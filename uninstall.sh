#!/bin/bash
# Removes the installed bin scripts, the VAD venv, the driving-mode skill, and saved state.
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local/bin}"
VENV="${HANDSFREE_VENV:-${XDG_DATA_HOME:-$HOME/.local/share}/claude-handsfree/venv}"
SKILLS_DIR="${SKILLS_DIR:-$HOME/.claude/skills}"
STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-handsfree"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "uninstall.sh: removes installed bins, the VAD venv, the driving-mode skill, and saved state."
  exit 0
fi

echo "==> Stopping any running listener"
"$PREFIX/drive-stop" 2>/dev/null || true

echo "==> Removing bin scripts from $PREFIX"
rm -f "$PREFIX/wispr-handsfree" "$PREFIX/wispr-turn" "$PREFIX/wispr-wait-quiet.py" \
      "$PREFIX/drive-say" "$PREFIX/drive-stop" "$PREFIX/drive-mode"

echo "==> Removing VAD venv at $VENV"
rm -rf "$VENV"

echo "==> Removing skill from $SKILLS_DIR/driving-mode"
rm -rf "$SKILLS_DIR/driving-mode"

echo "==> Removing saved state at $STATE_DIR"
rm -rf "$STATE_DIR"

echo "Uninstall complete."
