#!/usr/bin/env bash
# Detect if DP-3 (4K TV) is active and enabled (niri version)

# Check if DP-3 exists AND has a current_mode set (meaning it's actually enabled)
if niri msg -j outputs 2>/dev/null | jq -e '.[] | select(.name == "DP-3") | select(.current_mode != null)' > /dev/null 2>&1; then
    echo "TV_ON"
    exit 0
fi

echo "TV_OFF"
exit 1
