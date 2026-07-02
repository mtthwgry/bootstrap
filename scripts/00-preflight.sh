#!/usr/bin/env bash
# Verify platform and ensure Xcode Command Line Tools (git, cc) are present.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

info "checking platform"
require_macos_arm64
success "macOS arm64 confirmed"

if xcode-select -p >/dev/null 2>&1; then
  success "Xcode Command Line Tools present"
else
  warn "Xcode Command Line Tools missing"
  run xcode-select --install
  info "Finish the CLT installer, then re-run bootstrap."
  is_dry_run || exit 1
fi

# The Xcode license gate only applies when a FULL Xcode.app is the active developer
# dir. On a CLT-only machine `xcodebuild` still exists as a shim but errors ("requires
# Xcode ... is a command line tools instance"), and there is no license to accept — so
# only touch xcodebuild when the active dir is an actual .app.
DEVDIR="$(xcode-select -p 2>/dev/null || true)"
if [[ "$DEVDIR" == *.app/* ]]; then
  if xcodebuild -license check >/dev/null 2>&1; then
    success "Xcode license already accepted"
  else
    info "accepting Xcode license (needs sudo)"
    run sudo xcodebuild -license accept
  fi
else
  info "Command Line Tools only — no Xcode license step needed"
fi
