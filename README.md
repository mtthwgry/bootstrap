# bootstrap

Provision a fresh **macOS (Apple Silicon / arm64)** engineering laptop: Homebrew
packages, mise-managed language runtimes, dotfiles, Ghostty, VS Code, GitHub SSH,
and Claude Code. Pure Bash — runs on a clean machine with nothing pre-installed.

## Get the repo onto a fresh machine

A brand-new Mac has no `git` yet. Two ways in — pick one.

> Replace `OWNER` with your GitHub user/org in the commands below.

### A. No git — download the tarball with `curl` (fastest)

macOS ships `curl` and `tar`, so this needs nothing pre-installed:

```bash
mkdir -p ~/code && cd ~/code
curl -fsSL https://github.com/OWNER/bootstrap/archive/refs/heads/main.tar.gz | tar -xz
mv bootstrap-main bootstrap && cd bootstrap
```

Private repo? The tarball URL needs auth — either make it public, pass a token
(`curl -H "Authorization: Bearer $GH_TOKEN" …`), or use option B.

### B. With git — install Xcode Command Line Tools first

```bash
xcode-select --install                 # GUI installer — provides git; wait for it to finish
git clone https://github.com/OWNER/bootstrap.git ~/code/bootstrap
cd ~/code/bootstrap
```

## Run

```bash
# 1. ALWAYS preview first — changes nothing.
./bootstrap.sh --dry-run

# 2. Set your git identity (labels the SSH key + your commits).
export GIT_EMAIL="you@example.com"
printf '[user]\n\tname = Your Name\n\temail = you@example.com\n' > ~/.gitconfig.local

# 3. Run everything.
./bootstrap.sh
```

Steps run in order: **preflight** (platform + Xcode CLT/license) → **homebrew**
(Brewfile) → **mise** (runtimes) → **dotfiles** → **ghostty** → **vscode** →
**github** (interactive SSH wizard) → **claude**. It is idempotent — safe to
re-run; already-done work is skipped and any existing file is backed up to
`<file>.bak.<timestamp>` before it is symlinked.

The **github** step is interactive (it ports your SSH keys and writes
`~/.ssh/config`). It self-skips under `--dry-run` or a non-tty stdin.

### Selective runs

```bash
./bootstrap.sh --list                # show step names
./bootstrap.sh --only homebrew,mise  # run a subset
./bootstrap.sh --skip github         # skip steps
bash scripts/30-dotfiles.sh          # run one step standalone
```

## What it installs

| Area      | Details |
|-----------|---------|
| Packages  | `Brewfile` — git, gh, ripgrep, fd, bat, eza, fzf, git-delta, jq, gnupg, zsh-autosuggestions, … |
| GUI apps  | Ghostty, VS Code, OrbStack, Google Chrome, Figma, JetBrains Mono Nerd Font |
| Runtimes  | mise (standalone) + `config/mise/config.toml` — Node 24 LTS, Ruby 3.4, Python 3.13, Go, direnv |
| Dotfiles  | `dotfiles/` → symlinked into `$HOME` (`.zshrc`, `.zprofile`, `.aliases`, `.gitconfig`) |
| Editor    | VS Code settings + extensions (`config/vscode/`) |
| Git/SSH   | interactive wizard: port keys, macOS keychain, write `~/.ssh/config` (github + opt-in homelab) |
| Claude    | Claude Code via the official installer |

## Teardown

```bash
./teardown.sh                  # unlink repo symlinks + restore backups (safe)
./teardown.sh --mise           # also remove standalone mise + runtimes
./teardown.sh --packages       # also brew-uninstall everything in the Brewfile
./teardown.sh --all --dry-run  # preview a full teardown
```

Teardown only removes symlinks that point back into this repo and restores the
newest `.bak.<timestamp>`. It never deletes your SSH keys, `*.local` files, or
Claude Code.

## Safety

Every mutation runs through a `run` helper, so `--dry-run` shows exactly what
would happen. Steps are idempotent — re-running skips already-done work, and
`link_file` backs up any existing target to `<file>.bak.<timestamp>` before
symlinking. Machine-specific secrets/identity live in untracked `*.local` files.
