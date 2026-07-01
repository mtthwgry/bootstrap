# ~/.zprofile — login shell setup. Managed by bootstrap.

# Homebrew (Apple Silicon).
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# OrbStack CLI + integration (no-op until OrbStack is installed).
[[ -f "$HOME/.orbstack/shell/init.zsh" ]] && source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || :
