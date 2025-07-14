#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# Pretty Output (Bash-safe)
# -------------------------
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

info()    { echo -e "${YELLOW}→ $1${RESET}"; }
ok()      { echo -e "${GREEN}✓ $1${RESET}"; }
fail()    { echo -e "${RED}✖ $1${RESET}"; }

# -------------------------
# Check current shell
# -------------------------
if [[ "$SHELL" != */zsh ]]; then
  fail "Current shell is not zsh: $SHELL"
  echo "Switch to zsh with: chsh -s $(which zsh) && exec zsh"
  exit 1
fi

# -------------------------
# Check for oh-my-zsh
# -------------------------
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  ok "oh-my-zsh already installed"
else
  info "Installing oh-my-zsh..."

  export RUNZSH=no  # don't auto-launch shell
  export KEEP_ZSHRC=yes  # preserve any existing config

  # Run install script silently
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "oh-my-zsh installed"
  else
    fail "oh-my-zsh installation failed"
    exit 1
  fi
fi

# -------------------------
# Install Homebrew
# -------------------------
info "Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -d /usr/local/Homebrew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  ok "Homebrew installed"
else
  ok "Homebrew already installed"
fi

# -------------------------
# Install NVM via Homebrew
# -------------------------
if ! brew list nvm &>/dev/null; then
  info "Installing nvm via Homebrew..."
  brew install nvm
  ok "nvm installed"
else
  ok "nvm already installed"
fi

mkdir -p "$HOME/.nvm"
export NVM_DIR="$HOME/.nvm"
export NVM_SYMLINK_CURRENT=true
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# -------------------------
# Install Node.js LTS
# -------------------------
info "Installing latest LTS version of Node.js..."
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'
ok "Node.js $(node -v) installed via nvm"

# -------------------------
# Install Bitwarden CLI via npm
# -------------------------
if ! command -v bw &>/dev/null; then
  info "Installing bitwarden-cli via npm..."
  npm install -g @bitwarden/cli
  ok "bitwarden-cli installed"
else
  ok "bitwarden-cli already installed"
fi

# -------------------------
# Install Core Packages (excluding bitwarden-cli)
# -------------------------
core_packages=(git chezmoi)

install_if_missing() {
  local pkg="$1"
  echo "Processing: $pkg"
  if brew list "$pkg" &>/dev/null; then
    ok "$pkg already installed"
  else
    info "Installing $pkg..."
    brew install "$pkg"
    ok "$pkg installed"
  fi
}

for pkg in "${core_packages[@]}"; do
  install_if_missing "$pkg"
done

# -------------------------
# Bitwarden Login + Unlock
# -------------------------
info "Checking Bitwarden login status..."

BW_STATUS=$(bw status --raw)

if echo "$BW_STATUS" | grep -q '"status": "unauthenticated"'; then
  info "Not logged in. Logging into Bitwarden CLI..."
  echo -e "${YELLOW}You may be prompted to log in via browser or enter credentials.${RESET}"
  if bw login; then
    ok "Bitwarden login successful"
  else
    fail "Bitwarden login failed"
    exit 1
  fi
  BW_STATUS=$(bw status --raw)
fi

if echo "$BW_STATUS" | grep -q '"status": "locked"'; then
  info "Bitwarden vault is locked. Unlocking..."
  if BW_SESSION=$(bw unlock --raw); then
    export BW_SESSION
    ok "Bitwarden unlocked"
  else
    fail "Bitwarden unlock failed"
    exit 1
  fi
else
  ok "Bitwarden is already unlocked"
fi

# -------------------------
# Initialize Chezmoi Dotfiles
# -------------------------
info "Initializing chezmoi..."
chezmoi init --apply https://github.com/shaversj/dotfiles.git
ok "chezmoi initialized and dotfiles applied"

# -------------------------
# Switch dotfiles remote to SSH
# -------------------------
CHEZMOI_SRC=$(chezmoi source-path)
cd "$CHEZMOI_SRC"

info "Switching chezmoi git remote to SSH..."
git remote set-url origin git@github.com:shaversj/dotfiles.git
ok "Git remote updated to SSH: $(git remote get-url origin)"
