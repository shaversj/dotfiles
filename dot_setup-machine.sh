#!/usr/bin/env bash

set -euo pipefail

# -------------------------
# Pretty Output
# -------------------------
YELLOW="%F{yellow}"
GREEN="%F{green}"
RED="%F{red}"
RESET="%f"

info() { echo "${YELLOW}→ $1${RESET}"; }
ok()   { echo "${GREEN}✓ $1${RESET}"; }
fail() { echo "${RED}✖ $1${RESET}"; }

# -------------------------
# Install Homebrew
# -------------------------
info "Checking for Homebrew..."

if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  [[ -d /opt/homebrew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [[ -d /usr/local/Homebrew ]] && eval "$(/usr/local/bin/brew shellenv)"

  ok "Homebrew installed"
else
  ok "Homebrew already installed"
fi

# -------------------------
# Install Core Tools
# -------------------------
core_packages=(git bitwarden-cli chezmoi)

for pkg in $core_packages; do
  if brew list "$pkg" &>/dev/null; then
    ok "$pkg already installed"
  else
    info "Installing $pkg..."
    brew install "$pkg"
    ok "$pkg installed"
  fi
done

# -------------------------
# Bitwarden Login
# -------------------------
info "Logging into Bitwarden CLI..."
echo "${YELLOW}You may be prompted to login via browser or enter credentials.${RESET}"
bw login || { fail "Bitwarden login failed"; exit 1; }
ok "Bitwarden login successful"

# -------------------------
# Initialize Chezmoi Dotfiles
# -------------------------
info "Initializing chezmoi..."
chezmoi init --apply git@github.com:shaversj/dotfiles.git
ok "chezmoi initialized and applied"

# -------------------------
# Install Brewfile Software
# -------------------------
brewfile_path="$HOME/.brewfile"

if [[ -f "$brewfile_path" ]]; then
  info "Installing apps from Brewfile..."
  brew bundle --file="$brewfile_path"
  ok "Brewfile apps installed"
else
  fail "No Brewfile found in chezmoi source path: $brewfile_path"
fi
