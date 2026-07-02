#!/usr/bin/env bash
# Symlink Claude Code config from this repo into ~/.claude so settings, statusline,
# the global CLAUDE.md, custom skills, and agents stay in sync across machines.
# Session data (projects/, history, sessions/, ...) is left alone.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

SRC="$BOOTSTRAP_ROOT/config/claude"
DST="$HOME/.claude"

run mkdir -p "$DST"
link_file "$SRC/settings.json" "$DST/settings.json"
link_file "$SRC/statusline.sh" "$DST/statusline.sh"
link_file "$SRC/CLAUDE.md"     "$DST/CLAUDE.md"
link_file "$SRC/skills"        "$DST/skills"
link_file "$SRC/agents"        "$DST/agents"
