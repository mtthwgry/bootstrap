#!/usr/bin/env bash
# Opinionated macOS defaults for a dev machine. All user-domain (no sudo), reversible
# with `defaults delete`. Every write goes through run() so --dry-run previews them.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

info "applying macOS defaults"

# --- Keyboard: fast key repeat, disable press-and-hold accents (better for coding) ---
run defaults write NSGlobalDomain KeyRepeat -int 2
run defaults write NSGlobalDomain InitialKeyRepeat -int 15
run defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# --- Finder: show extensions, hidden files, path + status bars ---
run defaults write NSGlobalDomain AppleShowAllExtensions -bool true
run defaults write com.apple.finder AppleShowAllFiles -bool true
run defaults write com.apple.finder ShowPathbar -bool true
run defaults write com.apple.finder ShowStatusBar -bool true
run defaults write com.apple.finder _FXSortFoldersFirst -bool true
run defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # search current folder
run defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# --- Screenshots: PNG into ~/Screenshots ---
run mkdir -p "$HOME/Screenshots"
run defaults write com.apple.screencapture location -string "$HOME/Screenshots"
run defaults write com.apple.screencapture type -string "png"

# --- Dock: autohide, no recents ---
run defaults write com.apple.dock autohide -bool true
run defaults write com.apple.dock autohide-delay -float 0
run defaults write com.apple.dock show-recents -bool false
run defaults write com.apple.dock mru-spaces -bool false

# --- Panels: expand save/print dialogs by default ---
run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# Restart affected apps so changes show now (harmless if not running).
run killall Finder || true
run killall Dock || true
run killall SystemUIServer || true

success "macOS defaults applied (some need a logout/restart to fully take effect)"
