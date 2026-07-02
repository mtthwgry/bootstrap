#!/usr/bin/env bash
# Provision a fresh macOS (Apple Silicon) engineering laptop.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BOOTSTRAP_ROOT="$ROOT"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

# Ordered step registry: "<name>:<script path relative to repo root>".
STEPS=(
  "preflight:scripts/00-preflight.sh"
  "homebrew:scripts/10-homebrew.sh"
  "mise:scripts/20-mise.sh"
  "dotfiles:scripts/30-dotfiles.sh"
  "shell:scripts/35-shell.sh"
  "macos:scripts/45-macos-defaults.sh"
  "ghostty:scripts/40-ghostty.sh"
  "vscode:scripts/50-vscode.sh"
  "github:scripts/60-github-ssh.sh"
  "claude:scripts/70-claude-code.sh"
)

list_steps() { printf '%s\n' "${STEPS[@]%%:*}"; }

usage() {
  cat <<EOF
bootstrap.sh — provision a macOS (Apple Silicon) engineering laptop.

Usage:
  ./bootstrap.sh [options]

Options:
  -n, --dry-run       Print actions without changing anything.
  -o, --only <a,b>    Run only these steps (comma-separated).
  -s, --skip <a,b>    Skip these steps.
  -l, --list          List step names and exit.
  -h, --help          Show this help.

Steps (in order):
$(list_steps | sed 's/^/  - /')
EOF
}

ONLY=""; SKIP=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; export DRY_RUN; shift ;;
    -o|--only)    ONLY="$2"; shift 2 ;;
    -s|--skip)    SKIP="$2"; shift 2 ;;
    -l|--list)    list_steps; exit 0 ;;
    -h|--help)    usage; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
done

in_csv() { [[ ",$2," == *",$1,"* ]]; }

is_dry_run && info "DRY RUN — no changes will be made"

for entry in "${STEPS[@]}"; do
  name="${entry%%:*}"; script="${entry#*:}"
  [[ -n "$ONLY" ]] && ! in_csv "$name" "$ONLY" && continue
  [[ -n "$SKIP" ]] &&   in_csv "$name" "$SKIP" && continue
  step "$name"
  DRY_RUN="$DRY_RUN" BOOTSTRAP_ROOT="$ROOT" bash "$ROOT/$script"
done

success "bootstrap complete"
