#!/usr/bin/env bash
# Set display profile to Streaming mode

notify-send "🖥️ Display Profile" "Switching to Streaming mode..."
# Disable all other monitors
hyprctl keyword monitor "HDMI-A-1,disable"
hyprctl keyword monitor "HDMI-A-2,disable"
hyprctl keyword monitor "DP-1,disable"
# Enable only DP-2
hyprctl keyword monitor "DP-2,1920x1080@200,0x0,1"
notify-send "🖥️ Display Profile" "Streaming mode active (DP-2 only @ 200Hz)"
pkill -9 waybar && waybar &
