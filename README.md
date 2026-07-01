# bootstrap

Provision a fresh **macOS (Apple Silicon / arm64)** engineering laptop: Homebrew
packages, mise-managed language runtimes, dotfiles, Ghostty, VS Code, GitHub SSH,
and Claude Code. Pure Bash — runs on a clean machine with nothing pre-installed.

## Usage

```bash
git clone <this-repo> ~/code/bootstrap && cd ~/code/bootstrap

./bootstrap.sh --dry-run     # preview every action, change nothing
./bootstrap.sh               # run all steps
```

Set your git identity first so the SSH key and commits are labelled correctly:

```bash
export GIT_EMAIL="you@example.com"
printf '[user]\n\tname = Your Name\n\temail = you@example.com\n' > ~/.gitconfig.local
```

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
| Packages  | `Brewfile` (git, gh, mise, ripgrep, fd, bat, eza, fzf, delta, direnv, zoxide, …) |
| GUI apps  | Ghostty, VS Code, OrbStack, JetBrains Mono Nerd Font |
| Runtimes  | `config/mise/config.toml` — Node 24 LTS, Ruby 3.4, Python 3.13, Go |
| Dotfiles  | `dotfiles/` → symlinked into `$HOME` (`.zshrc`, `.aliases`, `.gitconfig`) |
| Editor    | VS Code settings + extensions (`config/vscode/`) |
| Git/SSH   | ed25519 key, macOS keychain, `~/.ssh/config`, prints key for GitHub |
| Claude    | Claude Code via the official installer |

## Safety

Every mutation runs through a `run` helper, so `--dry-run` shows exactly what
would happen. Steps are idempotent — re-running skips already-done work, and
`link_file` backs up any existing target to `<file>.bak.<timestamp>` before
symlinking. Machine-specific secrets/identity live in untracked `*.local` files.
