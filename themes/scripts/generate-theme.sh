#!/usr/bin/env bash
#
# Themix Theme Generator
# Generate a complete theme from a wallpaper image
# Orchestrates: extract-colors.py -> process-templates.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="${THEMES_DIR:-$HOME/.config/themes}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}${NC} $1"; }
log_success() { echo -e "${GREEN}${NC} $1"; }

show_usage() {
    cat << EOF
Usage: $0 <wallpaper-image> [theme-name] [options]

Generate a complete theme from a wallpaper image.

Arguments:
  wallpaper-image   Path to wallpaper image (jpg, png, etc.)
  theme-name        Name for the theme (default: derived from filename)

Options:
  --mode=MODE       Theme mode: dark, light, auto (default: auto)
  --apply           Apply the theme after generating
  -h, --help        Show this help message

Examples:
  $0 ~/Pictures/wallpaper.jpg
  $0 ~/Pictures/sunset.png my-sunset-theme
  $0 ~/Pictures/forest.jpg forest --apply
EOF
}

# Parse arguments
parse_args() {
    WALLPAPER=""
    THEME_NAME=""
    MODE="auto"
    APPLY=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode=*)
                MODE="${1#*=}"
                shift
                ;;
            --apply)
                APPLY=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$WALLPAPER" ]]; then
                    WALLPAPER="$1"
                elif [[ -z "$THEME_NAME" ]]; then
                    THEME_NAME="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$WALLPAPER" ]]; then
        echo "Error: Wallpaper image required"
        echo ""
        show_usage
        exit 1
    fi

    # Resolve wallpaper path
    WALLPAPER=$(realpath "$WALLPAPER" 2>/dev/null || echo "$WALLPAPER")

    if [[ ! -f "$WALLPAPER" ]]; then
        echo "Error: Wallpaper not found: $WALLPAPER"
        exit 1
    fi

    # Generate theme name from filename if not provided
    if [[ -z "$THEME_NAME" ]]; then
        local basename=$(basename "$WALLPAPER")
        THEME_NAME="${basename%.*}"  # Remove extension
        # Clean up name (replace spaces, special chars)
        THEME_NAME=$(echo "$THEME_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-_')
    fi
}

main() {
    parse_args "$@"

    echo "Generating theme: ${THEME_NAME}"
    echo "  Wallpaper: ${WALLPAPER}"
    echo "  Mode: ${MODE}"
    echo ""

    # Step 1: Extract colors
    log_info "Step 1: Extracting colors..."
    python3 "${SCRIPT_DIR}/extract-colors.py" "$WALLPAPER" "$THEME_NAME" --mode="$MODE" --quiet

    local theme_dir="${THEMES_DIR}/${THEME_NAME}"
    if [[ ! -f "${theme_dir}/colors.yaml" ]]; then
        echo "Error: Color extraction failed"
        exit 1
    fi
    log_success "Colors extracted to ${theme_dir}/colors.yaml"

    # Step 2: Process templates
    echo ""
    log_info "Step 2: Processing templates..."
    bash "${SCRIPT_DIR}/process-templates.sh" "$THEME_NAME"

    # Step 3: Optionally apply
    if [[ "$APPLY" == true ]]; then
        echo ""
        log_info "Step 3: Applying theme..."
        bash "${SCRIPT_DIR}/apply-theme.sh" "$THEME_NAME"
    else
        echo ""
        log_success "Theme '${THEME_NAME}' generated successfully!"
        echo ""
        echo "To apply: themix apply ${THEME_NAME}"
        echo "      or: ${SCRIPT_DIR}/apply-theme.sh ${THEME_NAME}"
    fi
}

main "$@"
