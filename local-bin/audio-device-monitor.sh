#!/usr/bin/env bash
# Monitor audio devices and auto-reconnect if they disappear

LAST_YETI_STATUS=""
LAST_ARCTIS_STATUS=""
CHECK_INTERVAL=5

check_device() {
    local pattern="$1"
    wpctl status 2>/dev/null | grep -qi "$pattern"
}

restart_audio() {
    notify-send -u normal -t 3000 "🔄 Audio" "Reconnecting audio devices..."
    systemctl --user restart wireplumber pipewire pipewire-pulse 2>/dev/null
    sleep 2
    # Refresh device mappings
    ~/.local/bin/audio-device-mapper.sh > /dev/null 2>&1
}

while true; do
    # Check Yeti
    if check_device "yeti"; then
        YETI_STATUS="connected"
    else
        YETI_STATUS="disconnected"
    fi

    # Check Arctis
    if check_device "arctis"; then
        ARCTIS_STATUS="connected"
    else
        ARCTIS_STATUS="disconnected"
    fi

    # Detect Yeti disconnect (was connected, now isn't)
    if [[ "$LAST_YETI_STATUS" == "connected" && "$YETI_STATUS" == "disconnected" ]]; then
        # Verify USB is still physically connected
        if lsusb | grep -qi "Blue Microphones"; then
            # USB present but software disconnected - restart audio
            restart_audio
            sleep 1
            if check_device "yeti"; then
                notify-send -u normal -t 3000 "✅ Audio" "Yeti Nano reconnected"
            else
                notify-send -u critical -t 5000 "❌ Audio" "Yeti Nano failed to reconnect"
            fi
        else
            notify-send -u critical -t 5000 "⚠️ Audio" "Yeti Nano unplugged"
        fi
    fi

    # Detect Arctis disconnect
    if [[ "$LAST_ARCTIS_STATUS" == "connected" && "$ARCTIS_STATUS" == "disconnected" ]]; then
        if lsusb | grep -qi "SteelSeries.*Arctis"; then
            restart_audio
            sleep 1
            if check_device "arctis"; then
                notify-send -u normal -t 3000 "✅ Audio" "Arctis Nova 7 reconnected"
            else
                notify-send -u critical -t 5000 "❌ Audio" "Arctis Nova 7 failed to reconnect"
            fi
        else
            notify-send -u normal -t 3000 "⚠️ Audio" "Arctis Nova 7 disconnected (wireless?)"
        fi
    fi

    LAST_YETI_STATUS="$YETI_STATUS"
    LAST_ARCTIS_STATUS="$ARCTIS_STATUS"

    sleep $CHECK_INTERVAL
done
