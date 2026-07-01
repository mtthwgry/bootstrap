#!/usr/bin/env bash
# Interactive SSH secrets wizard. Assumes you are PORTING keys from another machine:
# it helps you drop them in, fixes perms, loads them into the macOS keychain, and
# writes ~/.ssh/config. github.com is always configured; homelab hosts are opt-in.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

SSH_DIR="$HOME/.ssh"
CONFIG="$SSH_DIR/config"

run mkdir -p "$SSH_DIR"
run chmod 700 "$SSH_DIR"

# The wizard needs a terminal. Skip cleanly under --dry-run or when stdin is not a tty.
if is_dry_run || [[ ! -t 0 ]]; then
  info "ssh wizard is interactive — skipped under dry-run / non-tty"
  info "would: place keys in $SSH_DIR, fix perms, ssh-add --apple-use-keychain, write $CONFIG (github.com; homelab optional)"
  exit 0
fi

# ask <prompt> [default] -> echoes the answer (prompt shown on stderr).
ask() {
  local q="$1" def="${2:-}" ans
  if [[ -n "$def" ]]; then read -r -p "$q [$def]: " ans; else read -r -p "$q: " ans; fi
  printf '%s' "${ans:-$def}"
}
yesno() { local ans; read -r -p "$1 [y/N]: " ans; [[ "$ans" == [yY]* ]]; }

# --- Port keys from the old machine ---
info "Copy your key files into $SSH_DIR now."
info "  e.g. from the old machine:  scp ~/.ssh/github_ed25519* newmac:~/.ssh/"
read -r -p "Press Enter once your keys are in $SSH_DIR (or to skip and generate a fresh one)... " _

info "fixing permissions in $SSH_DIR"
find "$SSH_DIR" -type f -name '*.pub' -exec chmod 644 {} \;
find "$SSH_DIR" -type f ! -name '*.pub' ! -name 'known_hosts*' -exec chmod 600 {} \;

# --- GitHub (always) ---
GH_KEY_NAME="$(ask "GitHub key filename in $SSH_DIR" "github_ed25519")"
GH_KEY="$SSH_DIR/$GH_KEY_NAME"
if [[ ! -f "$GH_KEY" ]]; then
  if yesno "No $GH_KEY found — generate a new ed25519 key?"; then
    email="$(ask "Email/comment for the key" "${GIT_EMAIL:-$(whoami)@$(hostname -s)}")"
    ssh-keygen -t ed25519 -C "$email" -f "$GH_KEY" -N ""
  else
    warn "no GitHub key present — add one later and re-run this step"
  fi
fi

# --- Write a fresh ~/.ssh/config ---
info "writing $CONFIG"
{
  echo "# Managed by bootstrap (scripts/60-github-ssh.sh). Re-run the wizard to change hosts."
  echo "# OrbStack SSH hosts (no-op if OrbStack is absent)."
  echo "Include ~/.orbstack/ssh/config"
  echo ""
  echo "Host github.com"
  echo "  AddKeysToAgent yes"
  echo "  UseKeychain yes"
  echo "  IdentityFile $GH_KEY"
} > "$CONFIG"

[[ -f "$GH_KEY" ]] && ssh-add --apple-use-keychain "$GH_KEY" || true

# --- Homelab hosts (opt-in) ---
if yesno "Configure a homelab SSH host?"; then
  while : ; do
    hl_alias="$(ask "  Host alias" "homelab-01")"
    hl_name="$(ask "  HostName (IP or DNS)")"
    hl_user="$(ask "  User" "deploy")"
    hl_key="$(ask "  IdentityFile name in $SSH_DIR" "homelab_ed25519")"
    {
      echo ""
      echo "Host $hl_alias"
      [[ -n "$hl_name" ]] && echo "  HostName $hl_name"
      echo "  User $hl_user"
      echo "  IdentityFile $SSH_DIR/$hl_key"
      echo "  SetEnv TERM=xterm-256color"
    } >> "$CONFIG"
    [[ -f "$SSH_DIR/$hl_key" ]] && ssh-add --apple-use-keychain "$SSH_DIR/$hl_key" || true
    success "added host $hl_alias"
    yesno "Add another homelab host?" || break
  done
fi

chmod 600 "$CONFIG"
success "ssh config written: $CONFIG"

if [[ -f "$GH_KEY.pub" ]]; then
  info "GitHub public key — add at https://github.com/settings/keys :"
  cat "$GH_KEY.pub"
fi
info "verify with: ssh -T git@github.com"
