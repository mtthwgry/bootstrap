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

# Auto-accept the Xcode license if a full Xcode is installed and it is unaccepted.
# CLT-only machines have no license gate; xcodebuild is absent, so this is skipped.
if have xcodebuild && ! xcodebuild -license check >/dev/null 2>&1; then
  info "accepting Xcode license (needs sudo)"
  run sudo xcodebuild -license accept
fi
