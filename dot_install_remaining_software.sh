#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# Pretty Output
# -------------------------
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

info()    { echo -e "${YELLOW}→ $1${RESET}"; }
ok()      { echo -e "${GREEN}✓ $1${RESET}"; }
fail()    { echo -e "${RED}✖ $1${RESET}"; }

# -------------------------
# Verify Homebrew
# -------------------------
if ! command -v brew &>/dev/null; then
  fail "Homebrew is not installed. Please install Homebrew first."
  exit 1
fi

# -------------------------
# Verify Brewfile
# -------------------------
BREWFILE_PATH="$HOME/.brewfile"

if [[ ! -f "$BREWFILE_PATH" ]]; then
  fail "No Brewfile found at $BREWFILE_PATH"
  exit 1
fi

info "Using Brewfile at: $BREWFILE_PATH"

# -------------------------
# Install from Brewfile
# -------------------------
info "Installing packages defined in Brewfile..."

brew bundle --file="$BREWFILE_PATH"

ok "All packages from Brewfile installed"
