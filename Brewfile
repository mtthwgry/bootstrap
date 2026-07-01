# Brewfile — single source of truth for Homebrew packages.
# Apply with: brew bundle --file Brewfile
# Note: mise is NOT here — it is installed via its standalone installer (scripts/20-mise.sh).
#       direnv + node-gyp are managed by mise (config/mise/config.toml).

# --- Core CLI ---
brew "git"
brew "gh"          # GitHub CLI
brew "coreutils"

# --- Modern CLI utilities ---
brew "jq"
brew "ripgrep"
brew "fd"
brew "bat"
brew "eza"
brew "fzf"
brew "wget"
brew "git-delta"          # better git diffs
brew "tree"
brew "htop"
brew "tldr"
brew "gnupg"              # commit signing
brew "zsh-autosuggestions"

# --- Build deps for mise-managed runtimes (ruby-build, etc.) ---
brew "openssl@3"
brew "readline"
brew "libyaml"
brew "gmp"

# --- GUI apps ---
cask "ghostty"
cask "visual-studio-code"
cask "orbstack"                       # containers + linux VMs (Docker-compatible)
cask "figma"
cask "font-jetbrains-mono-nerd-font"
