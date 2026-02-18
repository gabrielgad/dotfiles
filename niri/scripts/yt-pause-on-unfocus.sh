#!/bin/bash
# Pause/play YouTube when its window loses/gains focus in niri

YT_APP_ID="brave-www.youtube.com__-Default"

# Build a lookup of window_id -> app_id from the event stream,
# so we never need a separate IPC call
declare -A window_apps
yt_focused=false

niri msg --json event-stream | while IFS= read -r line; do
    event=$(echo "$line" | jq -r 'keys[0]' 2>/dev/null) || continue

    case "$event" in
        WindowsChanged)
            # Initial dump - populate window map
            while IFS=$'\t' read -r wid app; do
                window_apps["$wid"]="$app"
            done < <(echo "$line" | jq -r '.WindowsChanged.windows[] | "\(.id)\t\(.app_id)"' 2>/dev/null)

            # Check if YT is already focused
            focused_app=$(echo "$line" | jq -r '.WindowsChanged.windows[] | select(.is_focused == true) | .app_id' 2>/dev/null)
            [ "$focused_app" = "$YT_APP_ID" ] && yt_focused=true
            ;;
        WindowOpenedOrChanged)
            wid=$(echo "$line" | jq -r '.WindowOpenedOrChanged.window.id' 2>/dev/null)
            app=$(echo "$line" | jq -r '.WindowOpenedOrChanged.window.app_id' 2>/dev/null)
            [ -n "$wid" ] && window_apps["$wid"]="$app"
            ;;
        WindowClosed)
            wid=$(echo "$line" | jq -r '.WindowClosed.id' 2>/dev/null)
            unset 'window_apps[$wid]'
            ;;
        WindowFocusChanged)
            focused_id=$(echo "$line" | jq -r '.WindowFocusChanged.id // empty' 2>/dev/null)

            if [ -n "$focused_id" ] && [ "$focused_id" != "null" ] && \
               [ "${window_apps[$focused_id]}" = "$YT_APP_ID" ]; then
                # YouTube gained focus
                if ! $yt_focused; then
                    playerctl play 2>/dev/null
                    yt_focused=true
                fi
            else
                # YouTube lost focus (or no window focused)
                if $yt_focused; then
                    playerctl pause 2>/dev/null
                    yt_focused=false
                fi
            fi
            ;;
    esac
done
