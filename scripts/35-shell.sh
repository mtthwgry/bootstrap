#!/usr/bin/env bash
# Ensure the login shell is zsh (our dotfiles are zsh). macOS defaults to zsh, but
# verify and fix. Uses system /bin/zsh — always present and already in /etc/shells,
# so no dependency on a brew-installed zsh.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

ZSH_BIN="/bin/zsh"
[[ -x "$ZSH_BIN" ]] || die "$ZSH_BIN not found"

if [[ "${SHELL:-}" == *zsh ]]; then
  success "login shell already zsh (${SHELL:-unknown})"
  exit 0
fi

# chsh requires the target shell to be listed in /etc/shells.
if ! grep -qx "$ZSH_BIN" /etc/shells 2>/dev/null; then
  info "adding $ZSH_BIN to /etc/shells (needs sudo)"
  if is_dry_run; then
    printf '%s\n' "[dry-run] echo $ZSH_BIN | sudo tee -a /etc/shells"
  else
    echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
  fi
fi

info "setting login shell to $ZSH_BIN (may prompt for your password)"
run chsh -s "$ZSH_BIN"
success "login shell set to zsh — open a new terminal for it to take effect"
