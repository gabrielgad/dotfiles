#!/usr/bin/env bash
# Display profile menu using wofi or direct argument (niri version)

# Check if an argument was provided
if [ -n "$1" ]; then
    selected="$1"
else
    # Kill any existing wofi instances before launching new one
    if pgrep -x wofi > /dev/null; then
        pkill -9 wofi
        sleep 0.1
    fi
    options="1. Normal\n2. Streaming\n3. TV"
    selected=$(echo -e "$options" | wofi --dmenu --prompt "Display Profile" --width 300 --height 200)
    selected=$(echo "$selected" | sed 's/^[0-9]*\. //')
fi

case $selected in
    "Streaming")
        # Streaming: Only HDMI-A-1 enabled at 200Hz
        notify-send "Display Profile" "Switching to Streaming mode..."

        # Enable HDMI-A-1 first
        niri msg output "HDMI-A-1" on
        niri msg output "HDMI-A-1" mode 1920x1080@200.000
        niri msg output "HDMI-A-1" position 0 0
        sleep 1

        # Disable other monitors
        niri msg output "DP-1" off
        niri msg output "DP-2" off
        niri msg output "DP-3" off

        # Focus workspace 2
        niri msg action focus-workspace 2
        notify-send "Display Profile" "Streaming mode active (HDMI-A-1 only @ 200Hz)"
        ;;
    "TV")
        # TV: Only DP-3 (Samsung Q80A) at 4K@120Hz
        notify-send "Display Profile" "Switching to TV mode..."

        # Enable TV first
        niri msg output "DP-3" on
        niri msg output "DP-3" mode 3840x2160@120.000
        niri msg output "DP-3" scale 2
        niri msg output "DP-3" position 0 0
        sleep 1

        # Disable other monitors
        niri msg output "DP-1" off
        niri msg output "DP-2" off
        niri msg output "HDMI-A-1" off

        niri msg action focus-workspace 10
        notify-send "Display Profile" "TV mode active (TV only @ 4K 120Hz)"
        ;;
    "Normal")
        # Normal: 3 monitors at 200Hz (no TV)
        notify-send "Display Profile" "Switching to Normal mode..."

        # Enable normal monitors
        niri msg output "DP-2" on
        niri msg output "DP-2" mode 1920x1080@200.000
        niri msg output "DP-2" position 0 0

        niri msg output "HDMI-A-1" on
        niri msg output "HDMI-A-1" mode 1920x1080@200.000
        niri msg output "HDMI-A-1" position 1920 0

        niri msg output "DP-1" on
        niri msg output "DP-1" mode 1920x1080@200.000
        niri msg output "DP-1" position 3840 0
        sleep 1

        # Disable TV
        niri msg output "DP-3" off

        niri msg action focus-workspace 1
        notify-send "Display Profile" "Normal mode active @ 200Hz (3 monitors, TV off)"
        ;;
    *)
        exit 0
        ;;
esac

# Restart waybar to handle display changes properly
pkill -9 waybar && waybar &
