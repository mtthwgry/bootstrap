#!/usr/bin/env bash
# Link VS Code user settings and install extensions from config/vscode/extensions.txt.
# VS Code itself is installed as a cask via the Brewfile.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

VS_USER="$HOME/Library/Application Support/Code/User"
link_file "$BOOTSTRAP_ROOT/config/vscode/settings.json" "$VS_USER/settings.json"

if have code; then
  info "installing VS Code extensions"
  while IFS= read -r ext; do
    [[ -z "$ext" || "$ext" == \#* ]] && continue
    run code --install-extension "$ext" --force
  done < "$BOOTSTRAP_ROOT/config/vscode/extensions.txt"
else
  warn "'code' CLI not found — in VS Code run: Shell Command: Install 'code' command in PATH"
fi
