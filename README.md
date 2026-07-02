# bootstrap

Provision a fresh **macOS (Apple Silicon / arm64)** engineering laptop: Homebrew
packages, mise-managed language runtimes, dotfiles, Ghostty, VS Code, GitHub SSH,
and Claude Code. Pure Bash — runs on a clean machine with nothing pre-installed.

## Get the repo onto a fresh machine

Public repo — no auth needed. A brand-new Mac has no `git`, but it does ship
`curl` + `tar`, so the tarball path needs nothing pre-installed. Fork? Swap
`mtthwgry` for your own user/org.

### A. No git — download the tarball (recommended, zero deps)

```bash
mkdir -p ~/code && cd ~/code
curl -fsSL https://api.github.com/repos/mtthwgry/bootstrap/tarball/main | tar -xz
mv mtthwgry-bootstrap-* bootstrap && cd bootstrap
./bootstrap.sh
```

### B. With git (needs Xcode Command Line Tools)

```bash
xcode-select --install                 # provides git; wait for the GUI installer
git clone https://github.com/mtthwgry/bootstrap.git ~/code/bootstrap
cd ~/code/bootstrap
```

The HTTPS clone above is read-only. Once bootstrap has set up your SSH key,
switch the remote so you can push without a password:

```bash
git remote set-url origin git@github.com:mtthwgry/bootstrap.git
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
(Brewfile) → **mise** (runtimes) → **dotfiles** → **shell** (login shell → zsh) →
**macos** (defaults) → **ghostty** → **vscode** → **github** (interactive SSH wizard) →
**claude** (install) → **claude-config** (symlink ~/.claude). It is idempotent — safe to
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
| GUI apps  | Ghostty, VS Code, OrbStack, Chrome, Figma, Raycast, Slack, Linear, Postico, JetBrains Mono Nerd Font |
| macOS     | `defaults` step — fast key-repeat, Finder extensions/hidden, screenshots → ~/Screenshots, Dock autohide |
| Runtimes  | mise (standalone) + `config/mise/config.toml` — Node 24 LTS, Ruby 3.4, Python 3.13, Go, direnv |
| Dotfiles  | `dotfiles/` → symlinked into `$HOME` (`.zshrc`, `.zprofile`, `.aliases`, `.gitconfig`) |
| Editor    | VS Code settings + extensions (`config/vscode/`) |
| Git/SSH   | interactive wizard: port keys, macOS keychain, write `~/.ssh/config` (github + opt-in homelab) |
| Claude    | Claude Code via the official installer; `~/.claude` config (settings, statusline, CLAUDE.md, skills, agents) symlinked from `config/claude/` |

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
