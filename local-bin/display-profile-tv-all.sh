#!/usr/bin/env bash
# Set display profile to TV mode with all monitors

notify-send "🖥️ Display Profile" "Switching to TV + All Monitors mode..."

# Disable all monitors first
hyprctl keyword monitor "HDMI-A-2,disable"
hyprctl keyword monitor "DP-2,disable"
hyprctl keyword monitor "HDMI-A-1,disable"
hyprctl keyword monitor "DP-1,disable"

sleep 1

# Enable TV at top at 60Hz (position 0x-2160 means 2160 pixels above y=0)
hyprctl keyword monitor "HDMI-A-2,3840x2160@60,0x-2160,2"

# Enable bottom row monitors (left to right at y=0)
hyprctl keyword monitor "DP-2,1920x1080@200,0x0,1"
hyprctl keyword monitor "HDMI-A-1,1920x1080@200,1920x0,1"
hyprctl keyword monitor "DP-1,1920x1080@200,3840x0,1"

notify-send "🖥️ Display Profile" "TV + All Monitors active (TV @ top 60Hz, bottom row @ 200Hz)"

# Restart waybar to handle display changes properly
pkill -9 waybar && waybar &
