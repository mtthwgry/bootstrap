# ~/.zshrc — interactive shell setup. Managed by bootstrap (symlinked from the repo).

# mise — language runtime manager (standalone install in ~/.local/bin).
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

# direnv — per-directory env. DIRENV_BASH points at the nix-provided bash (homelab).
[[ -x "$HOME/.nix-profile/bin/bash" ]] && export DIRENV_BASH="$HOME/.nix-profile/bin/bash"
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# History.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS INC_APPEND_HISTORY

# Completion.
autoload -Uz compinit && compinit

# zsh-autosuggestions (from Homebrew).
_zsh_autosuggest="$(brew --prefix 2>/dev/null)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "$_zsh_autosuggest" ]] && source "$_zsh_autosuggest"

export EDITOR="code"
export VISUAL="code"

# Aliases + optional local, untracked overrides.
[[ -f "$HOME/.aliases" ]]     && source "$HOME/.aliases"
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
