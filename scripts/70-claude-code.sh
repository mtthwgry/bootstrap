#!/usr/bin/env bash
# Install Claude Code via the official installer. Idempotent: skips if already present.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

if have claude; then
  success "Claude Code already installed ($(command -v claude))"
  exit 0
fi

info "installing Claude Code"
if is_dry_run; then
  printf '%s\n' "[dry-run] curl -fsSL https://claude.ai/install.sh | bash"
else
  curl -fsSL https://claude.ai/install.sh | bash
fi
