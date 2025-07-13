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
# Install Homebrew
# -------------------------
info "Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Load shellenv for Apple Silicon or Intel
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
# Install Core Tools
# -------------------------
core_packages=(git bitwarden-cli chezmoi)

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
