#!/usr/bin/env bash
DEVICE_MAP="/tmp/audio-device-map"
~/.local/bin/audio-device-mapper.sh > /dev/null 2>&1
source "$DEVICE_MAP"
wpctl set-default $HDMI_SINK
wpctl set-default $YETI_SOURCE
notify-send -u normal -t 3000 "🎧 Audio" "HDMI + Yeti"
