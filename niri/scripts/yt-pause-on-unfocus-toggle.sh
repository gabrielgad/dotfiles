#!/bin/bash
# Toggle YouTube pause-on-unfocus on/off

if pkill -f yt-pause-on-unfocus.sh; then
    notify-send "YouTube Focus" "Auto-pause disabled" --icon=media-playback-start -t 2000
else
    ~/.config/niri/scripts/yt-pause-on-unfocus.sh &
    disown
    notify-send "YouTube Focus" "Auto-pause enabled" --icon=media-playback-pause -t 2000
fi
