#!/usr/bin/env bash
# Install Homebrew (if absent) and apply the Brewfile.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

BREW_PREFIX="/opt/homebrew"

if have brew; then
  success "Homebrew present"
else
  info "installing Homebrew"
  if is_dry_run; then
    printf '%s\n' "[dry-run] install Homebrew via get.brew.sh install script"
  else
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

# Load brew into this shell so `brew bundle` works in the same run.
if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
fi

if have brew; then
  info "applying Brewfile"
  run brew bundle --file "$BOOTSTRAP_ROOT/Brewfile"
else
  is_dry_run || die "brew not on PATH after install"
fi
