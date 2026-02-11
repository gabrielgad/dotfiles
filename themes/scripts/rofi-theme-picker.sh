#!/usr/bin/env bash
#
# Rofi Theme Picker for Themix

THEMES_DIR="${HOME}/.config/themes"

# Get themes list from themix CLI
themes=$("${THEMES_DIR}/themix" list 2>/dev/null)

# Show in rofi
selected=$(echo "$themes" | rofi -dmenu -p "Theme" -theme ~/.config/rofi/theme.rasi)
[[ -z "$selected" ]] && exit 0

# Extract theme name (remove leading markers/whitespace)
theme_name=$(echo "$selected" | sed 's/^[* ] //')

# Apply the theme
exec "${THEMES_DIR}/themix" apply "$theme_name"
