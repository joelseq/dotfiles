#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---------------------------------------------------------------------------
# Colored output helpers
# ---------------------------------------------------------------------------
info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------------------
# 1. Detect OS
# ---------------------------------------------------------------------------
detect_os() {
  case "$(uname -s)" in
    Linux) OS="linux" ;;
    *)     error "Unsupported OS: $(uname -s)"; exit 1 ;;
  esac

  if command -v apt-get &>/dev/null; then
    PKG_MGR="apt"
  elif command -v dnf &>/dev/null; then
    PKG_MGR="dnf"
  else
    error "No supported package manager found (need apt-get or dnf)"; exit 1
  fi

  ok "Detected OS: $OS (pkg manager: $PKG_MGR)"
}

# ---------------------------------------------------------------------------
# 2. Install system prerequisites
# ---------------------------------------------------------------------------
install_prerequisites() {
  info "Installing system prerequisites..."

  if [[ "$PKG_MGR" == "apt" ]]; then
    sudo apt-get update -y
    sudo apt-get install -y zsh git curl build-essential procps file
  elif [[ "$PKG_MGR" == "dnf" ]]; then
    sudo dnf groupinstall -y 'Development Tools'
    sudo dnf install -y zsh git curl procps-ng file
  fi

  ok "System prerequisites installed"
}

# ---------------------------------------------------------------------------
# 3. Install Homebrew (linuxbrew)
# ---------------------------------------------------------------------------
install_homebrew() {
  if command -v brew &>/dev/null; then
    ok "Homebrew already installed"
    return 0
  fi

  # Check known linuxbrew paths
  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    ok "Homebrew already installed (added to PATH)"
    return 0
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
    ok "Homebrew already installed (added to PATH)"
    return 0
  fi

  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
  fi

  ok "Homebrew installed"
}

# ---------------------------------------------------------------------------
# 4. Install brew packages
# ---------------------------------------------------------------------------
install_brew_packages() {
  info "Installing brew packages..."

  local packages=(
    neovim
    fzf
    ripgrep
    fd
    eza
    starship
    direnv
    zsh-syntax-highlighting
    zsh-autosuggestions
    tmux
    lazygit
    yazi
    bat
    jq
    tree-sitter
    hub
    rbenv
    mise
  )

  brew install "${packages[@]}"

  # Graphite CLI
  brew tap withgraphite/tap
  brew install withgraphite/tap/graphite

  # fzf shell integration
  if [[ ! -f ~/.fzf.zsh ]]; then
    info "Setting up fzf shell integration..."
    "$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
    ok "fzf shell integration configured"
  else
    ok "fzf shell integration already configured"
  fi

  # tmuxinator via gem (avoid brew pulling in its own ruby)
  if ! command -v tmuxinator &>/dev/null; then
    info "Installing tmuxinator via gem..."
    gem install tmuxinator
    ok "tmuxinator installed"
  else
    ok "tmuxinator already installed"
  fi

  ok "Brew packages installed"
}

# ---------------------------------------------------------------------------
# 5. Install oh-my-zsh
# ---------------------------------------------------------------------------
install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "oh-my-zsh already installed"
    return 0
  fi

  info "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  ok "oh-my-zsh installed"
}

# ---------------------------------------------------------------------------
# 6. Install nvm + Node.js
# ---------------------------------------------------------------------------
install_nvm() {
  local nvm_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"

  if [[ -s "$nvm_dir/nvm.sh" ]]; then
    ok "nvm already installed at $nvm_dir"
  else
    info "Installing nvm..."
    mkdir -p "$nvm_dir"
    export NVM_DIR="$nvm_dir"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    ok "nvm installed"
  fi

  export NVM_DIR="$nvm_dir"
  # shellcheck disable=SC1091
  [[ -s "$nvm_dir/nvm.sh" ]] && . "$nvm_dir/nvm.sh"

  if ! command -v node &>/dev/null; then
    info "Installing Node.js LTS via nvm..."
    nvm install --lts
    ok "Node.js installed"
  else
    ok "Node.js already available"
  fi
}

# ---------------------------------------------------------------------------
# 7. Install rbenv + ruby-build
# ---------------------------------------------------------------------------
install_ruby_build() {
  local rbenv_root
  rbenv_root="$(rbenv root 2>/dev/null || echo "$HOME/.rbenv")"

  if [[ -d "$rbenv_root/plugins/ruby-build" ]]; then
    ok "ruby-build already installed"
    return 0
  fi

  info "Installing ruby-build plugin..."
  mkdir -p "$rbenv_root/plugins"
  git clone https://github.com/rbenv/ruby-build.git "$rbenv_root/plugins/ruby-build"
  ok "ruby-build installed"
}

# ---------------------------------------------------------------------------
# 8. Set default shell to zsh
# ---------------------------------------------------------------------------
set_default_shell() {
  if [[ "$SHELL" == *"zsh"* ]]; then
    ok "Default shell is already zsh"
    return 0
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"

  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    info "Adding $zsh_path to /etc/shells..."
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  info "Changing default shell to zsh..."
  chsh -s "$zsh_path"
  ok "Default shell set to zsh (restart terminal to take effect)"
}

# ---------------------------------------------------------------------------
# 9. Back up existing dotfiles that conflict with dotbot symlinks
# ---------------------------------------------------------------------------
backup_existing_dotfiles() {
  local backup_dir="$HOME/.dotfiles-backup"
  local files_to_check=(.zshrc .bashrc .vimrc)
  local backed_up=0

  for file in "${files_to_check[@]}"; do
    if [[ -f "$HOME/$file" && ! -L "$HOME/$file" ]]; then
      mkdir -p "$backup_dir"
      mv "$HOME/$file" "$backup_dir/$file.$(date +%s)"
      backed_up=$((backed_up + 1))
      ok "Backed up ~/$file to $backup_dir/$file"
    fi
  done

  if [[ $backed_up -eq 0 ]]; then
    ok "No conflicting dotfiles to back up"
  fi
}

# ---------------------------------------------------------------------------
# 10. Copy claude config (before dotbot so symlinks are skipped)
# ---------------------------------------------------------------------------
copy_claude_config() {
  local claude_dir="$HOME/.claude"
  local source_dir="$DOTFILES_DIR/config/claude"

  if [[ ! -d "$source_dir" ]]; then
    warn "Claude config source not found at $source_dir, skipping"
    return 0
  fi

  mkdir -p "$claude_dir"

  for file in "$source_dir"/*; do
    local filename
    filename="$(basename "$file")"
    if [[ ! -e "$claude_dir/$filename" ]]; then
      cp "$file" "$claude_dir/$filename"
      ok "Copied $filename to $claude_dir/"
    else
      ok "$claude_dir/$filename already exists, skipping"
    fi
  done

  ok "Claude config in place"
}

# ---------------------------------------------------------------------------
# 11. Run dotbot (./install)
# ---------------------------------------------------------------------------
run_dotbot() {
  info "Running dotbot to symlink dotfiles..."
  bash "$DOTFILES_DIR/install"
  ok "Dotfiles symlinked"
}

# ---------------------------------------------------------------------------
# 12. Install neovim plugins
# ---------------------------------------------------------------------------
install_nvim_plugins() {
  if ! command -v nvim &>/dev/null; then
    warn "neovim not found, skipping plugin install"
    return 0
  fi

  info "Installing neovim plugins (lazy.nvim sync)..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null
  ok "Neovim plugins installed"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  info "Starting dotfiles bootstrap from $DOTFILES_DIR"
  echo ""

  detect_os
  install_prerequisites
  install_homebrew
  install_brew_packages
  install_oh_my_zsh
  install_nvm
  install_ruby_build
  set_default_shell
  copy_claude_config
  backup_existing_dotfiles
  run_dotbot
  install_nvim_plugins

  echo ""
  ok "Bootstrap complete!"
}

main "$@"
