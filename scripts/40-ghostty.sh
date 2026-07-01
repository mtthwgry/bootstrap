#!/usr/bin/env bash
# Link the Ghostty config. Ghostty itself is installed as a cask via the Brewfile.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

link_file "$BOOTSTRAP_ROOT/config/ghostty/config" "$HOME/.config/ghostty/config"

[[ -d "/Applications/Ghostty.app" ]] \
  || warn "Ghostty.app not found yet — installed via 'brew bundle' (homebrew step)"
