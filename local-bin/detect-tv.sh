#!/usr/bin/env bash
# Detect if DP-3 (4K TV) is active and enabled

# Check if TV exists in monitor list
if ! hyprctl monitors | grep -q "^Monitor DP-3"; then
    echo "TV_OFF"
    exit 1
fi

# Check if TV is disabled
if hyprctl monitors | grep -A5 "^Monitor DP-3" | grep -q "disabled: true"; then
    echo "TV_OFF"
    exit 1
fi

# TV is connected and enabled
echo "TV_ON"
exit 0
