#!/usr/bin/env bash
# Set display profile to Normal mode

notify-send "🖥️ Display Profile" "Switching to Normal mode..."
# Disable TV first
hyprctl keyword monitor "HDMI-A-2,disable"
# Enable main monitors
hyprctl keyword monitor "DP-2,1920x1080@200,0x0,1"
hyprctl keyword monitor "HDMI-A-1,1920x1080@200,1920x0,1"
hyprctl keyword monitor "DP-1,1920x1080@200,3840x0,1"
notify-send "🖥️ Display Profile" "Normal mode active @ 200Hz (DP-2 + HDMI-A-1 + DP-1)"
pkill -9 waybar && waybar &
