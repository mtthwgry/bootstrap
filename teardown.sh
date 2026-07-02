#!/usr/bin/env bash
# Undo bootstrap. By default: only remove symlinks this repo created and restore
# the newest backup for each. NEVER touches secrets (~/.ssh, ~/.gitconfig.local,
# ~/.zshrc.local) or any file it does not own.
#
# Destructive layers are opt-in:
#   --mise      also uninstall the standalone mise + its runtimes/caches
#   --packages  also `brew uninstall` every formula/cask in the Brewfile
#   --all       both of the above
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BOOTSTRAP_ROOT="$ROOT"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

DO_MISE=0; DO_PKGS=0
usage() {
  cat <<EOF
teardown.sh — reverse bootstrap.sh.

Usage:
  ./teardown.sh [options]

Options:
  -n, --dry-run    Print actions without changing anything.
      --mise       Also uninstall standalone mise + runtimes.
      --packages   Also brew-uninstall everything in the Brewfile.
      --all        Same as --mise --packages.
  -h, --help       Show this help.

Always preserved: ~/.ssh (keys + config), ~/.gitconfig.local, ~/.zshrc.local,
Claude Code, and any file/symlink not created by this repo.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; export DRY_RUN; shift ;;
    --mise)       DO_MISE=1; shift ;;
    --packages)   DO_PKGS=1; shift ;;
    --all)        DO_MISE=1; DO_PKGS=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
done

is_dry_run && info "DRY RUN — no changes will be made"

# --- 1. Unlink config symlinks + restore backups (always) ---
step "unlink dotfiles + configs"

shopt -s dotglob nullglob
for path in "$ROOT/dotfiles"/*; do
  unlink_file "$HOME/$(basename "$path")"
done
shopt -u dotglob nullglob

unlink_file "$HOME/.config/mise/config.toml"
unlink_file "$HOME/.config/ghostty/config"
unlink_file "$HOME/Library/Application Support/Code/User/settings.json"
unlink_file "$HOME/.claude/settings.json"
unlink_file "$HOME/.claude/statusline.sh"
unlink_file "$HOME/.claude/CLAUDE.md"
unlink_file "$HOME/.claude/skills"
unlink_file "$HOME/.claude/agents"

# --- 2. mise (opt-in) ---
if [[ "$DO_MISE" == "1" ]]; then
  step "remove mise + runtimes"
  run rm -f  "$HOME/.local/bin/mise"
  run rm -rf "$HOME/.local/share/mise" "$HOME/.local/state/mise" "$HOME/.cache/mise"
  success "mise removed"
fi

# --- 3. Homebrew packages (opt-in) ---
if [[ "$DO_PKGS" == "1" ]]; then
  step "brew uninstall Brewfile packages"
  if have brew; then
    while IFS= read -r line; do
      case "$line" in
        brew\ \"*)
          name="${line#brew \"}"; name="${name%%\"*}"
          run brew uninstall --ignore-dependencies "$name" || warn "skip (not installed?): $name" ;;
        cask\ \"*)
          name="${line#cask \"}"; name="${name%%\"*}"
          run brew uninstall --cask "$name" || warn "skip (not installed?): $name" ;;
      esac
    done < "$ROOT/Brewfile"
  else
    warn "brew not present — nothing to uninstall"
  fi
fi

echo ""
info "Preserved (not touched): ~/.ssh, ~/.gitconfig.local, ~/.zshrc.local, Claude Code."
info "Older *.bak.* backups are left in place; delete them manually if unwanted."
success "teardown complete"
