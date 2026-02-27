#!/usr/bin/env bash
DEVICE_MAP="/tmp/audio-device-map"
~/.local/bin/audio-device-mapper.sh > /dev/null 2>&1
source "$DEVICE_MAP"
wpctl set-default $ARCTIS_SINK
wpctl set-default $ARCTIS_SOURCE
notify-send -u normal -t 3000 "🎧 Audio" "Arctis Nova 7"
