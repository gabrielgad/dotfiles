#!/usr/bin/env nu
# Map audio devices by description (most durable - ignores USB ports, serials, PCI addresses)

let DEVICE_MAP = "/tmp/audio-device-map"

# Parse pactl output into records of {name, description}
def parse-pactl-list [type: string] {
    ^pactl list $type | lines
    | reduce -f {items: [], current: {name: "", desc: ""}} {|line, acc|
        if ($line | str starts-with "	Name:") {
            let name = ($line | str replace "	Name: " "" | str trim)
            {items: $acc.items, current: {name: $name, desc: ""}}
        } else if ($line | str starts-with "	Description:") {
            let desc = ($line | str replace "	Description: " "" | str trim)
            let item = {name: $acc.current.name, desc: $desc}
            {items: ($acc.items | append $item), current: {name: "", desc: ""}}
        } else {
            $acc
        }
    }
    | get items
    | where name != ""
}

# Find sink/source name by description pattern
def find-by-desc [items: list<record>, pattern: string] {
    let matches = ($items | where {|it| $it.desc =~ $pattern})
    if ($matches | is-empty) { "" } else { $matches | first | get name }
}

# Get all sinks and sources
let sinks = (parse-pactl-list "sinks")
let sources = (parse-pactl-list "sources")

# Match by description patterns (stable across hardware changes)
let ARCTIS_SINK = (find-by-desc $sinks "(?i)arctis.*nova.*analog")
# Exclude "Monitor of" by matching start of description
let ARCTIS_SOURCE = (find-by-desc $sources "(?i)^arctis.*nova.*mono")
let STARSHIP_SINK = (find-by-desc $sinks "(?i)starship.*digital|digital.*iec958")
let HDMI_SINK = (find-by-desc $sinks "(?i)hdmi.*digital stereo")
let FIFINE_SOURCE = (find-by-desc $sources "(?i)^fifine.*microphone.*analog")

# Write mappings
$"ARCTIS_SINK=($ARCTIS_SINK)
ARCTIS_SOURCE=($ARCTIS_SOURCE)
STARSHIP_SINK=($STARSHIP_SINK)
HDMI_SINK=($HDMI_SINK)
FIFINE_SOURCE=($FIFINE_SOURCE)" | save -f $DEVICE_MAP

print "Audio device mapping updated:"
open $DEVICE_MAP
