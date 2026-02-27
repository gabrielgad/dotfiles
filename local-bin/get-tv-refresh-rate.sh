#!/usr/bin/env bash
# Detects the best available refresh rate for the TV (HDMI-A-3) at its current or specified resolution

# Default to 4K if no resolution specified
RESOLUTION="${1:-3840x2160}"

# Get available modes for HDMI-A-3 and find the highest refresh rate for the specified resolution
# Use sed to extract just the availableModes line, which has all modes on one line
tv_refresh=$(hyprctl monitors all | sed -n '/Monitor HDMI-A-3/,/^$/p' | grep "availableModes:" | \
             grep -oP "${RESOLUTION}@\K[0-9.]+(?=Hz)" | sort -rn | head -1)

# Output just the refresh rate number
echo "$tv_refresh"
