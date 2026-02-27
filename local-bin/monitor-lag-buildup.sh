#!/usr/bin/env bash
# Monitor what's building up when HKC monitor is disabled

echo "Monitoring system while disabling HDMI-A-1..."
echo "Starting baseline measurements..."

# Baseline
journalctl -k -n 0 -f > /tmp/kernel-log-during-disable.txt &
JOURNAL_PID=$!

echo "Disabling HDMI-A-1..."
hyprctl keyword monitor "HDMI-A-1,disable"

echo "Monitoring for 10 seconds while lag builds up..."
for i in {1..10}; do
    echo "Second $i:"
    echo "  Interrupts: $(grep nvidia /proc/interrupts | awk '{print $2+$16}')"
    echo "  Open files: $(lsof -p $(pgrep Hyprland) 2>/dev/null | wc -l)"
    sleep 1
done

echo "Killing journal monitor..."
kill $JOURNAL_PID 2>/dev/null

echo "Re-enabling HDMI-A-1..."
hyprctl keyword monitor "HDMI-A-1,1920x1080@75,0x2160,1"

echo "Kernel messages during disable:"
cat /tmp/kernel-log-during-disable.txt | head -50
