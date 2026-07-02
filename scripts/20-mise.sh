#!/usr/bin/env bash
# Install mise via its standalone installer (to ~/.local/bin), link the global
# config, and install the pinned language runtimes. Not from Homebrew, by design.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

MISE="$HOME/.local/bin/mise"

if [[ -x "$MISE" ]]; then
  success "mise present ($MISE)"
else
  info "installing mise (standalone)"
  if is_dry_run; then
    printf '%s\n' "[dry-run] curl https://mise.run | sh"
  else
    curl -fsSL https://mise.run | sh
  fi
fi

link_file "$BOOTSTRAP_ROOT/config/mise/config.toml" "$HOME/.config/mise/config.toml"

# Put mise on PATH for this step. Some tool backends (e.g. the npm backend's
# node/npm shims) shell out to `mise` during install; without it on PATH they
# fail with "mise: command not found" (exit 127).
export PATH="$HOME/.local/bin:$PATH"

if have mise; then
  info "installing language runtimes via mise"
  run mise install
else
  is_dry_run || die "mise not found at $MISE after install"
fi
