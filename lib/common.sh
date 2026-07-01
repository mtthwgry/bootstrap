#!/usr/bin/env bash
# Shared helpers for bootstrap scripts. Source this; do not execute directly.

# Guard against double-sourcing.
[[ -n "${_COMMON_SH_LOADED:-}" ]] && return 0
_COMMON_SH_LOADED=1

# Repo root = parent of this lib/ dir, unless already exported by the orchestrator.
BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export BOOTSTRAP_ROOT

# 1 = print actions only, change nothing. Inherited from the environment.
DRY_RUN="${DRY_RUN:-0}"

# Colors, disabled when stdout is not a tty or NO_COLOR is set.
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  _c_reset=$'\033[0m'; _c_red=$'\033[31m'; _c_grn=$'\033[32m'
  _c_ylw=$'\033[33m'; _c_blu=$'\033[34m'; _c_dim=$'\033[2m'
else
  _c_reset=; _c_red=; _c_grn=; _c_ylw=; _c_blu=; _c_dim=
fi

info()    { printf '%s\n' "${_c_blu}==>${_c_reset} $*"; }
step()    { printf '\n%s\n' "${_c_blu}### $*${_c_reset}"; }
success() { printf '%s\n' "${_c_grn}ok${_c_reset} $*"; }
warn()    { printf '%s\n' "${_c_ylw}warning:${_c_reset} $*" >&2; }
error()   { printf '%s\n' "${_c_red}error:${_c_reset} $*" >&2; }
die()     { error "$*"; exit 1; }

is_dry_run() { [[ "$DRY_RUN" == "1" ]]; }
have()       { command -v "$1" >/dev/null 2>&1; }

# run <cmd...> — the mutation primitive. Executes normally, prints only under dry-run.
# Every state-changing command must go through run() (or an explicit is_dry_run guard).
run() {
  if is_dry_run; then
    printf '%s\n' "${_c_dim}[dry-run] $*${_c_reset}"
  else
    printf '%s\n' "${_c_dim}+ $*${_c_reset}"
    "$@"
  fi
}

# Abort unless running on macOS / Apple Silicon.
require_macos_arm64() {
  [[ "$(uname -s)" == "Darwin" ]] || die "macOS required (got $(uname -s))"
  [[ "$(uname -m)" == "arm64" ]]  || die "Apple Silicon (arm64) required (got $(uname -m))"
}

# link_file <source> <target> — idempotent symlink. Backs up any existing target
# to <target>.bak.<timestamp> before linking. Skips if already linked correctly.
link_file() {
  local src="$1" dst="$2"
  [[ -e "$src" ]] || { warn "source missing, skip: $src"; return 0; }

  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    success "linked (already): $dst"
    return 0
  fi

  run mkdir -p "$(dirname "$dst")"

  if [[ -e "$dst" || -L "$dst" ]]; then
    local backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    warn "backing up existing $dst -> $backup"
    run mv "$dst" "$backup"
  fi

  run ln -s "$src" "$dst"
  success "linked: $dst -> $src"
}

# unlink_file <target> — reverse of link_file. Removes the symlink ONLY if it points
# into $BOOTSTRAP_ROOT (i.e. we created it), then restores the newest
# <target>.bak.<timestamp> if one exists. Leaves anything it does not own untouched.
unlink_file() {
  local dst="$1"
  if [[ -L "$dst" ]]; then
    local tgt; tgt="$(readlink "$dst")"
    if [[ "$tgt" == "$BOOTSTRAP_ROOT"/* ]]; then
      run rm -f "$dst"
      success "unlinked: $dst"
    else
      warn "not ours, leaving: $dst -> $tgt"
      return 0
    fi
  elif [[ -e "$dst" ]]; then
    warn "not a symlink, leaving as-is: $dst"
    return 0
  else
    return 0
  fi

  local newest
  newest="$(ls -1d "${dst}".bak.* 2>/dev/null | sort | tail -n1)"
  if [[ -n "$newest" ]]; then
    run mv "$newest" "$dst"
    success "restored backup: $newest -> $dst"
  fi
}
