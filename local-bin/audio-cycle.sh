#!/usr/bin/env bash
# Cycle through audio profiles: Arctis+Fifine -> Arctis+Arctis -> Starship -> HDMI(TV)

STATE_FILE="/tmp/audio-cycle-state"
DEVICE_MAP="/tmp/audio-device-map"

# Refresh device mappings
~/.local/bin/audio-device-mapper.sh > /dev/null 2>&1
source "$DEVICE_MAP"

# Read current state (default to 0)
current=$(cat "$STATE_FILE" 2>/dev/null || echo "0")

# Cycle to next
next=$(( (current + 1) % 4 ))
echo "$next" > "$STATE_FILE"

case $next in
    0)
        wpctl set-default "$ARCTIS_SINK"
        wpctl set-default "$FIFINE_SOURCE"
        notify-send -u normal -t 3000 "Audio" "Arctis Nova 7 + Fifine Mic"
        ;;
    1)
        wpctl set-default "$ARCTIS_SINK"
        wpctl set-default "$ARCTIS_SOURCE"
        notify-send -u normal -t 3000 "Audio" "Arctis Nova 7 + Arctis Mic"
        ;;
    2)
        wpctl set-default "$STARSHIP_SINK"
        wpctl set-default "$FIFINE_SOURCE"
        notify-send -u normal -t 3000 "Audio" "Starship Soundbar"
        ;;
    3)
        wpctl set-default "$HDMI_SINK"
        wpctl set-default "$FIFINE_SOURCE"
        notify-send -u normal -t 3000 "Audio" "TV (HDMI)"
        ;;
esac
