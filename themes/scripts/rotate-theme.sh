#!/usr/bin/env bash
#
# Themix Theme Rotator
# Rotate to a random or daily theme

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="${THEMES_DIR:-$HOME/.config/themes}"

# Directories to exclude from theme selection
EXCLUDE_DIRS="scripts templates operations pure loaders current proof-of-concept"

# Get list of available themes
get_themes() {
    local themes=()
    for dir in "${THEMES_DIR}"/*/; do
        [[ ! -d "$dir" ]] && continue
        local name=$(basename "$dir")

        # Skip excluded directories
        local skip=false
        for exclude in $EXCLUDE_DIRS; do
            [[ "$name" == "$exclude" ]] && skip=true && break
        done
        [[ "$skip" == true ]] && continue

        # Skip hidden directories
        [[ "$name" == .* ]] && continue

        # Must have colors.yaml to be a valid theme
        [[ -f "${dir}/colors.yaml" ]] && themes+=("$name")
    done

    printf '%s\n' "${themes[@]}" | sort
}

# Select theme based on mode
select_theme() {
    local mode="$1"
    local themes
    mapfile -t themes < <(get_themes)

    if [[ ${#themes[@]} -eq 0 ]]; then
        echo "No themes found" >&2
        exit 1
    fi

    if [[ "$mode" == "daily" ]]; then
        # Use date as seed for consistent daily selection
        local day_seed=$(date +%Y%m%d)
        local index=$((day_seed % ${#themes[@]}))
        echo "${themes[$index]}"
    else
        # Random selection
        local index=$((RANDOM % ${#themes[@]}))
        echo "${themes[$index]}"
    fi
}

show_usage() {
    cat << EOF
Usage: $0 [options]

Rotate to a random or daily theme.

Options:
  --daily, -d     Use same theme for the whole day (based on date)
  --random, -r    Random theme selection (default)
  --list, -l      List available themes
  --current, -c   Show current theme
  -h, --help      Show this help message

Examples:
  $0              # Random theme
  $0 --daily      # Same theme all day
  $0 --list       # List themes
EOF
}

main() {
    local mode="random"
    local action="rotate"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --daily|-d)
                mode="daily"
                shift
                ;;
            --random|-r)
                mode="random"
                shift
                ;;
            --list|-l)
                action="list"
                shift
                ;;
            --current|-c)
                action="current"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    case "$action" in
        list)
            echo "Available themes:"
            get_themes | while read -r theme; do
                echo "  $theme"
            done
            ;;
        current)
            if [[ -L "${THEMES_DIR}/current" ]]; then
                basename "$(readlink "${THEMES_DIR}/current")"
            else
                echo "No current theme set"
            fi
            ;;
        rotate)
            local selected=$(select_theme "$mode")
            echo "Applying theme: ${selected}"
            bash "${SCRIPT_DIR}/apply-theme.sh" "$selected"
            ;;
    esac
}

main "$@"
