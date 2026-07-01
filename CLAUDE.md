# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Bootstrap toolkit that provisions a fresh **macOS (Apple Silicon / arm64)** engineering laptop: Homebrew packages, mise-managed language runtimes, dotfiles, Ghostty, VS Code, GitHub SSH, and Claude Code. Pure Bash, no runtime dependencies beyond what macOS ships — it must run on a clean machine before anything is installed.

## Commands

```bash
./bootstrap.sh                    # run all steps in order
./bootstrap.sh --dry-run          # print every action, change nothing (use FIRST)
./bootstrap.sh --list             # list step names
./bootstrap.sh --only brew,mise   # run a subset by name
./bootstrap.sh --skip github      # skip steps by name
bash scripts/30-dotfiles.sh       # run one step standalone
brew bundle --file Brewfile       # (re)apply Homebrew packages only
```

There is no build or test suite. Validate changes by running the relevant step (or the whole thing) with `--dry-run` and reading the printed actions.

## Architecture

`bootstrap.sh` is the orchestrator. It defines an ordered `STEPS` registry of `name:scriptpath` entries and runs each `scripts/NN-*.sh` as a **child bash process**, passing `DRY_RUN` and `BOOTSTRAP_ROOT` through the environment. `--only`/`--skip` filter by step name.

`lib/common.sh` is sourced by every script and is the contract all steps follow:
- **`run <cmd...>`** — the mutation primitive. Executes normally; under `--dry-run` it *prints only*. Every state-changing command MUST go through `run` (or an explicit `is_dry_run` guard for pipes/heredocs), or `--dry-run` becomes a lie. This invariant is the whole safety model.
- **`link_file <src> <dst>`** — idempotent symlink; if `dst` already points at `src` it skips, otherwise backs the existing target up to `<dst>.bak.<timestamp>` before linking.
- `require_macos_arm64`, `have <cmd>`, and logging (`info/step/success/warn/error/die`).

Two config-delivery patterns:
- **`dotfiles/`** → symlinked *flat* into `$HOME` (each entry `x` becomes `~/x`) by `30-dotfiles.sh`.
- **`config/`** → app configs symlinked to app-specific paths by their own step: mise → `~/.config/mise/config.toml`, ghostty → `~/.config/ghostty/config`, vscode → `~/Library/Application Support/Code/User/settings.json`.

Sources of truth:
- **`Brewfile`** — brew formulae and casks (`ghostty`, `visual-studio-code`, `orbstack`, CLI utils). Prefer adding packages here over `brew install` calls in scripts. `mise` is deliberately NOT here.
- **mise** is installed via its **standalone installer** to `~/.local/bin/mise` (`scripts/20-mise.sh`), not Homebrew. Scripts and `.zshrc` reference it by absolute path since it is not on `PATH` during a fresh run.
- **`config/mise/config.toml`** — pinned language runtimes (Node/Ruby/Python/Go) plus `direnv` and `npm:node-gyp`. Not the Brewfile.
- **`config/vscode/extensions.txt`** — one extension id per line (`code --list-extensions` format); `#` comments allowed.

The `github` step (`scripts/60-github-ssh.sh`) is an **interactive wizard** — it reads from the tty to port keys, fix perms, load the keychain, and write `~/.ssh/config` (github.com always, homelab hosts opt-in). It self-skips under `--dry-run` or a non-tty stdin, so full runs stay automatable.

## Conventions

- Every step script is **independently runnable** and **idempotent** — re-running is safe; already-done work is detected and skipped.
- Step scripts start with `set -euo pipefail` and source `lib/common.sh` via a path relative to their own location (`.../lib/common.sh`), so they work whether invoked by the orchestrator or directly.
- **Never hardcode machine identity or secrets.** Git name/email go in `~/.gitconfig.local` (git-ignored, `[include]`d from the tracked `.gitconfig`); shell overrides in `~/.zshrc.local`. Untracked `*.local` files are the escape hatch.
- **Add a step:** write `scripts/NN-name.sh` (source common, do idempotent work through `run`/`link_file`), then register `"name:scripts/NN-name.sh"` in the `STEPS` array in `bootstrap.sh`. Numeric prefix sets order.
- Steps assume ordering: `preflight` (platform + Xcode CLT/license) → `homebrew` (installs brew + everything in Brewfile) → the rest. Anything depending on a brew-installed tool must run after `homebrew`.
