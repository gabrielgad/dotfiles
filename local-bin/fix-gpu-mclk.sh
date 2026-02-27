#!/bin/bash
# Fix AMD GPU MCLK to prevent display blanking (forces high performance mode)
# Cycle through auto first to reset power management state after suspend
echo "auto" | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level > /dev/null
sleep 0.5
echo "high" | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level > /dev/null
