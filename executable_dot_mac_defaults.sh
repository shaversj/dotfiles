#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# Keyboard → Text settings
# -------------------------

# Disable: "Capitalize words automatically"
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
echo "✓ Disabled automatic capitalization"

# Disable: "Correct spelling automatically"
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
echo "✓ Disabled automatic spell correction"

# -------------------------
# Mouse → Point & Click
# -------------------------

# Disable: "Scroll direction: Natural"
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
echo "✓ Disabled scroll direction: natural"

# -------------------------
# Dock → Hide Automatically
# -------------------------

# Enable auto-hide for Dock
defaults write com.apple.dock autohide -bool true
echo "✓ Enabled Dock auto-hide"

# Apply changes to Dock immediately
killall Dock

# Apply changes to SystemUIServer (some keyboard settings)
killall SystemUIServer
