#!/bin/bash
# Installs the claude-handsfree bins, the driving-mode skill, and the VAD venv. Safe to re-run.
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local/bin}"
VENV="${HANDSFREE_VENV:-${XDG_DATA_HOME:-$HOME/.local/share}/claude-handsfree/venv}"
SKILLS_DIR="${SKILLS_DIR:-$HOME/.claude/skills}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<'EOF'
install.sh

Builds the Swift key-event helper, creates a Python venv with the VAD
dependency, and installs the bin scripts and the driving-mode skill.
Safe to re-run (idempotent).

Env vars:
  PREFIX              Where to install the bin scripts (default: $HOME/.local/bin)
  SKILLS_DIR          Where to install the skill (default: $HOME/.claude/skills)
  HANDSFREE_VENV      Where to create the VAD venv
                      (default: ${XDG_DATA_HOME:-$HOME/.local/share}/claude-handsfree/venv)
  HANDSFREE_SKIP_OPEN Set to 1 to skip opening System Settings at the end
EOF
  exit 0
fi

echo "==> Checking requirements"
if [ "$(uname -s)" != "Darwin" ]; then
  echo "error: this project only runs on macOS (uses CGEvent + Wispr Flow)." >&2
  exit 1
fi
command -v swiftc >/dev/null 2>&1 || { echo "error: swiftc not found (install Xcode Command Line Tools: xcode-select --install)" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "error: python3 not found." >&2; exit 1; }
if ! command -v sox >/dev/null 2>&1; then
  echo "sox (for \`rec\`) is required for the VAD listener and was not found."
  if command -v brew >/dev/null 2>&1; then
    read -r -p "Install it now with 'brew install sox'? [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      brew install sox
    else
      echo "warning: continuing without sox; the listener (wispr-turn) will not work until it's installed." >&2
    fi
  else
    echo "warning: Homebrew not found; install sox manually, then re-run this script." >&2
  fi
fi

echo "==> Building wispr-handsfree"
mkdir -p "$PREFIX"
swiftc -O "$REPO_DIR/bin/wispr-handsfree.swift" -o "$PREFIX/wispr-handsfree"

echo "==> Creating VAD venv at $VENV"
mkdir -p "$(dirname "$VENV")"
if [ ! -x "$VENV/bin/python" ]; then
  python3 -m venv "$VENV"
fi
"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet webrtcvad-wheels

echo "==> Installing bin scripts to $PREFIX"
install -m 755 "$REPO_DIR/bin/wispr-turn" "$PREFIX/wispr-turn"
install -m 755 "$REPO_DIR/bin/wispr-wait-quiet.py" "$PREFIX/wispr-wait-quiet.py"
install -m 755 "$REPO_DIR/bin/drive-say" "$PREFIX/drive-say"
install -m 755 "$REPO_DIR/bin/drive-stop" "$PREFIX/drive-stop"
install -m 755 "$REPO_DIR/bin/drive-mode" "$PREFIX/drive-mode"

echo "==> Installing driving-mode skill to $SKILLS_DIR/driving-mode"
mkdir -p "$SKILLS_DIR/driving-mode"
cp "$REPO_DIR/skills/driving-mode/SKILL.md" "$SKILLS_DIR/driving-mode/SKILL.md"

cat <<EOF

Install complete.

Permissions needed once:
  1. Accessibility - the terminal app (or whatever runs these scripts) must
     be allowed to send key events. Opening System Settings now; add your
     terminal app under Privacy & Security > Accessibility, then toggle it on.
  2. Microphone - macOS will prompt the first time \`rec\` (sox) records audio.
     Allow it.

Make sure $PREFIX is on your PATH, then run:
  drive-mode on
  drive-say --listen "testing, can you hear me"
EOF

if [ "${HANDSFREE_SKIP_OPEN:-0}" != "1" ]; then
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null || true
fi
