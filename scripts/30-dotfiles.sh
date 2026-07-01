#!/usr/bin/env bash
# Symlink every entry in dotfiles/ flat into $HOME (dotfiles/x -> ~/x).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

DOTS="$BOOTSTRAP_ROOT/dotfiles"
info "symlinking dotfiles from $DOTS"

shopt -s dotglob nullglob
for path in "$DOTS"/*; do
  link_file "$path" "$HOME/$(basename "$path")"
done
shopt -u dotglob nullglob
