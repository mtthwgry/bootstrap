# ~/.zprofile — login shell setup. Managed by bootstrap.

# Homebrew (Apple Silicon).
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# OrbStack CLI + integration (no-op until OrbStack is installed).
if [[ -f "$HOME/.orbstack/shell/init.zsh" ]]; then
  source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || :
elif [[ -d /Applications/OrbStack.app/Contents/MacOS/xbin ]]; then
  # OrbStack's own CLI setup didn't run; expose its bundled docker/kubectl tools directly.
  export PATH="/Applications/OrbStack.app/Contents/MacOS/xbin:$PATH"
fi
