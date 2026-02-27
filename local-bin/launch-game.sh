#!/usr/bin/env bash
# Dynamic game launcher for Steam games
# Auto-detects compositor (Hyprland or niri) and moves game windows appropriately

# Debug log
exec 2>> /tmp/launch-game.log
echo "=== $(date) ===" >&2
echo "Args: $@" >&2

# Fix for 8BitDo controller input duplication bug
export SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT="0x2dc8/0x301b"
export SDL_JOYSTICK_HIDAPI=0

# Detect compositor
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    COMPOSITOR="hyprland"
else
    COMPOSITOR="niri"
fi

# Detect target based on TV state
if [ "$COMPOSITOR" = "hyprland" ]; then
    if ~/.local/bin/detect-tv.sh; then
        echo "Launching game on TV workspace (DP-3)" >&2
        TARGET_WORKSPACE=10
    else
        echo "Launching game on HDMI-A-1 workspace" >&2
        TARGET_WORKSPACE=2
    fi
else
    if ~/.local/bin/detect-tv-niri.sh; then
        echo "Launching game on TV (DP-3)" >&2
        TARGET_MONITOR="DP-3"
    else
        echo "Launching game on center monitor (HDMI-A-1)" >&2
        TARGET_MONITOR="HDMI-A-1"
    fi
fi

# Hyprland: wait for game windows and move to workspace
wait_and_move_hyprland() {
    local target_workspace=$1
    local max_attempts=60
    local attempt=0
    local total_windows_moved=0
    local idle_checks=0
    local max_idle_checks=20

    echo "Waiting for game windows to appear..." >&2

    while [ $attempt -lt $max_attempts ]; do
        GAME_WINDOWS=$(hyprctl clients -j | jq -r ".[] | select(.class | startswith(\"steam_app_\")) | select(.workspace.id != $target_workspace) | .address")

        if [ -n "$GAME_WINDOWS" ]; then
            idle_checks=0
            BATCH_CMD=""
            for WINDOW_ADDRESS in $GAME_WINDOWS; do
                WINDOW_INFO=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$WINDOW_ADDRESS\")")
                WINDOW_TITLE=$(echo "$WINDOW_INFO" | jq -r '.title')

                echo "Moving game window '$WINDOW_TITLE' to workspace $target_workspace" >&2

                BATCH_CMD+="dispatch focuswindow address:$WINDOW_ADDRESS;"
                BATCH_CMD+="dispatch moveoutofgroup;"
                BATCH_CMD+="dispatch movetoworkspace $target_workspace,address:$WINDOW_ADDRESS;"
                total_windows_moved=$((total_windows_moved + 1))
            done

            if [ -n "$BATCH_CMD" ]; then
                BATCH_CMD+="dispatch workspace $target_workspace;"
                hyprctl --batch "$BATCH_CMD"
            fi
            sleep 0.1
        else
            if [ $total_windows_moved -gt 0 ]; then
                idle_checks=$((idle_checks + 1))
                if [ $idle_checks -ge $max_idle_checks ]; then
                    echo "Moved $total_windows_moved window(s) successfully" >&2
                    return 0
                fi
            fi
        fi

        sleep 0.3
        attempt=$((attempt + 1))
    done

    if [ $total_windows_moved -gt 0 ]; then
        echo "Timeout reached, moved $total_windows_moved window(s)" >&2
    else
        echo "Warning: No game windows appeared within timeout" >&2
    fi
}

# niri: wait for game windows and move to monitor
wait_and_move_niri() {
    local target_monitor=$1
    local max_attempts=60
    local attempt=0
    local total_windows_moved=0
    local idle_checks=0
    local max_idle_checks=20

    echo "Waiting for game windows to appear..." >&2

    while [ $attempt -lt $max_attempts ]; do
        # Get all game window IDs (steam_app_* or *.exe for Proton games)
        WINDOW_IDS=$(niri msg -j windows 2>/dev/null | jq -r '.[] | select(.app_id | (startswith("steam_app_") or endswith(".exe"))) | .id')

        if [ -n "$WINDOW_IDS" ]; then
            WORKSPACES=$(niri msg -j workspaces 2>/dev/null)
            WINDOWS=$(niri msg -j windows 2>/dev/null)

            for WINDOW_ID in $WINDOW_IDS; do
                WS_ID=$(echo "$WINDOWS" | jq -r ".[] | select(.id == $WINDOW_ID) | .workspace_id")
                WINDOW_TITLE=$(echo "$WINDOWS" | jq -r ".[] | select(.id == $WINDOW_ID) | .title")
                CURRENT_OUTPUT=$(echo "$WORKSPACES" | jq -r ".[] | select(.id == $WS_ID) | .output")

                if [ "$CURRENT_OUTPUT" != "$target_monitor" ]; then
                    echo "Moving '$WINDOW_TITLE' from $CURRENT_OUTPUT to $target_monitor" >&2
                    niri msg action move-window-to-monitor --id "$WINDOW_ID" "$target_monitor"
                    total_windows_moved=$((total_windows_moved + 1))
                fi
            done
            sleep 0.1
        fi

        if [ $total_windows_moved -gt 0 ]; then
            idle_checks=$((idle_checks + 1))
            if [ $idle_checks -ge $max_idle_checks ]; then
                echo "Moved $total_windows_moved window(s) successfully" >&2
                return 0
            fi
        fi

        sleep 0.3
        attempt=$((attempt + 1))
    done

    if [ $total_windows_moved -gt 0 ]; then
        echo "Timeout reached, moved $total_windows_moved window(s)" >&2
    else
        echo "Warning: No game windows appeared within timeout" >&2
    fi
}

# Launch game
"$@" &
GAME_PID=$!

# Move windows based on compositor
if [ "$COMPOSITOR" = "hyprland" ]; then
    wait_and_move_hyprland "$TARGET_WORKSPACE"
else
    wait_and_move_niri "$TARGET_MONITOR"
fi

wait $GAME_PID
