#!/usr/bin/env bash
# Set display profile to TV mode

notify-send "🖥️ Display Profile" "Switching to TV mode..."
# Disable other monitors first
hyprctl keyword monitor "DP-2,disable"
hyprctl keyword monitor "HDMI-A-1,disable"
hyprctl keyword monitor "DP-1,disable"
# Enable TV at 119.88Hz with 2x scaling (logical size becomes 1920x1080)
hyprctl keyword monitor "HDMI-A-2,3840x2160@119.88,0x0,2.0"
notify-send "🖥️ Display Profile" "TV mode active (TV only @ 120Hz with 2x UI scaling)"
pkill -9 waybar && waybar &
