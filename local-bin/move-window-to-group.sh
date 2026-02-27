#!/usr/bin/env bash
# Move window to workspace group while staying on same monitor

# Get target group (1, 2, or 3)
TARGET_GROUP=$1

if [ -z "$TARGET_GROUP" ]; then
    echo "Usage: $0 <group_number>"
    exit 1
fi

# Get current window's monitor ID
MONITOR_ID=$(hyprctl activewindow -j | jq -r '.monitor')

# Get monitor name from ID
CURRENT_MONITOR=$(hyprctl monitors -j | jq -r ".[] | select(.id == $MONITOR_ID) | .name")

# Map monitor to workspace based on target group
# Layout: DP-2 (left) | HDMI-A-1 (center) | DP-1 (right)
case "$CURRENT_MONITOR" in
    "DP-2")
        # Left monitor: groups 1->1, 2->4, 3->7
        case "$TARGET_GROUP" in
            1) TARGET_WORKSPACE=1 ;;
            2) TARGET_WORKSPACE=4 ;;
            3) TARGET_WORKSPACE=7 ;;
        esac
        ;;
    "HDMI-A-1")
        # Center monitor: groups 1->2, 2->5, 3->8
        case "$TARGET_GROUP" in
            1) TARGET_WORKSPACE=2 ;;
            2) TARGET_WORKSPACE=5 ;;
            3) TARGET_WORKSPACE=8 ;;
        esac
        ;;
    "DP-1")
        # Right monitor: groups 1->3, 2->6, 3->9
        case "$TARGET_GROUP" in
            1) TARGET_WORKSPACE=3 ;;
            2) TARGET_WORKSPACE=6 ;;
            3) TARGET_WORKSPACE=9 ;;
        esac
        ;;
    "DP-3")
        # TV: always workspace 10
        TARGET_WORKSPACE=10
        ;;
    *)
        echo "Unknown monitor: $CURRENT_MONITOR"
        exit 1
        ;;
esac

# Check if window is Brave and handle specially
WINDOW_CLASS=$(hyprctl activewindow -j | jq -r '.class')
WINDOW_ADDRESS=$(hyprctl activewindow -j | jq -r '.address')

if [[ "$WINDOW_CLASS" == "brave-browser" ]]; then
    # For Brave: exit fullscreen first, move, then restore if needed
    WAS_FULLSCREEN=$(hyprctl activewindow -j | jq -r '.fullscreen')

    if [[ "$WAS_FULLSCREEN" != "0" ]]; then
        hyprctl dispatch fullscreen 0
        sleep 0.1
    fi

    # Move window to target workspace silently
    hyprctl dispatch movetoworkspacesilent $TARGET_WORKSPACE
else
    # Move window to target workspace silently
    hyprctl dispatch movetoworkspacesilent $TARGET_WORKSPACE
fi
