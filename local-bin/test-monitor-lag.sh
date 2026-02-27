#!/usr/bin/env bash
# Test script to capture what's happening during monitor disable lag

echo "Starting monitor lag test..."
echo "Capturing interrupt baseline..."
cat /proc/interrupts | grep nvidia > /tmp/interrupts-before.txt

echo "Disabling HDMI-A-1 and HDMI-A-2..."
hyprctl keyword monitor "HDMI-A-1,disable"
hyprctl keyword monitor "HDMI-A-2,disable"

echo "Sleeping 5 seconds while lag occurs..."
sleep 5

echo "Capturing interrupt counts during lag..."
cat /proc/interrupts | grep nvidia > /tmp/interrupts-during.txt

echo "Re-enabling monitors..."
hyprctl keyword monitor "HDMI-A-1,1920x1080@75,0x2160,1"
hyprctl keyword monitor "HDMI-A-2,1920x1080@75,3840x2160,1"

echo "Test complete. Checking interrupt difference..."
echo "Before:"
cat /tmp/interrupts-before.txt
echo ""
echo "During:"
cat /tmp/interrupts-during.txt
