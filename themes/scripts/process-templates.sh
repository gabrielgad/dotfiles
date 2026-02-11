#!/usr/bin/env bash
#
# Themix Template Processor
# Process templates and replace {{color.path}} placeholders with values from colors.yaml
# Requires: bash, python3, PyYAML, ImageMagick (for brave images)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="${THEMES_DIR:-$HOME/.config/themes}"
TEMPLATES_DIR="${THEMES_DIR}/templates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}${NC} $1"; }
log_success() { echo -e "${GREEN}${NC} $1"; }
log_warn() { echo -e "${YELLOW}${NC} $1"; }
log_error() { echo -e "${RED}${NC} $1" >&2; }

# Process a single template using Python (handles complex values properly)
process_template() {
    local template_path="$1"
    local theme_name="$2"
    local theme_dir="${THEMES_DIR}/${theme_name}"
    local colors_file="${theme_dir}/colors.yaml"
    local overrides_file="${theme_dir}/overrides.yaml"

    # Determine output path
    local relative_path="${template_path#$TEMPLATES_DIR/}"
    local output_name="${relative_path%.template}"

    # Special handling for kvantum (needs theme name in path)
    if [[ "$relative_path" == kvantum/* ]]; then
        output_name="kvantum/${theme_name}/${theme_name}.kvconfig"
    fi

    local output_file="${theme_dir}/${output_name}"
    local output_dir="$(dirname "$output_file")"

    mkdir -p "$output_dir"

    # Use Python for template processing (handles all value types properly)
    # NOTE: Using double quotes inside Python because heredoc expands shell vars
    python3 << PYTHON_SCRIPT
import yaml
import re
import sys

def get_nested_value(data, path):
    keys = path.split(".")
    value = data
    for key in keys:
        if isinstance(value, dict) and key in value:
            value = value[key]
        else:
            return None
    if isinstance(value, list):
        return str(value)
    elif isinstance(value, bool):
        return str(value)
    else:
        return str(value)

# Load colors
with open("$colors_file", "r") as f:
    colors = yaml.safe_load(f)

# Load overrides if exists
overrides = {}
try:
    with open("$overrides_file", "r") as f:
        overrides = yaml.safe_load(f) or {}
except:
    pass

# Merge overrides into colors
def deep_merge(base, override):
    result = base.copy()
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result

colors = deep_merge(colors, overrides)

# Read template
with open("$template_path", "r") as f:
    content = f.read()

# Find and replace all {{placeholder}} patterns
def replace_placeholder(match):
    key_path = match.group(1)
    value = get_nested_value(colors, key_path)
    if value is None:
        print("  Warning: No value for " + key_path, file=sys.stderr)
        return match.group(0)
    return value

content = re.sub(r"\{\{([^}]+)\}\}", replace_placeholder, content)

# Write output
with open("$output_file", "w") as f:
    f.write(content)
PYTHON_SCRIPT
}

# Generate oomox colors file from colors.yaml
generate_oomox_file() {
    local theme_name="$1"
    local theme_dir="${THEMES_DIR}/${theme_name}"
    local colors_file="${theme_dir}/colors.yaml"
    local oomox_file="${theme_dir}/colors-oomox"

    python3 << PYTHON_SCRIPT
import yaml

with open("$colors_file", "r") as f:
    data = yaml.safe_load(f)

oomox = data.get("oomox", {})
lines = []
for key, value in oomox.items():
    if key in ["roundness", "spacing", "gradient"]:
        lines.append(key.upper() + "=" + str(value))
    elif key == "gtk3_generate_dark":
        lines.append("GTK3_GENERATE_DARK=" + str(value))
    elif key == "name":
        lines.append("NAME=" + str(value))
    else:
        val = str(value).lstrip("#")
        lines.append(key.upper() + "=" + val)

with open("$oomox_file", "w") as f:
    f.write("\n".join(lines))
PYTHON_SCRIPT
}

# Generate Brave theme images using ImageMagick
generate_brave_images() {
    local theme_name="$1"
    local theme_dir="${THEMES_DIR}/${theme_name}"
    local colors_file="${theme_dir}/colors.yaml"
    local brave_dir="${theme_dir}/brave-theme"
    local images_dir="${brave_dir}/images"

    [[ ! -d "$brave_dir" ]] && return 0

    mkdir -p "$images_dir"

    # Get colors using Python
    local colors_output
    colors_output=$(python3 << PYTHON_SCRIPT
import yaml
with open("$colors_file", "r") as f:
    data = yaml.safe_load(f)
print(data["surface"]["primary"], data["surface"]["secondary"], data["surface"]["tertiary"])
PYTHON_SCRIPT
)

    local frame_color toolbar_color tab_color
    read frame_color toolbar_color tab_color <<< "$colors_output"

    # Generate solid color PNGs
    if command -v magick &>/dev/null; then
        magick -size 1x128 "xc:${frame_color}" "${images_dir}/theme_frame.png"
        magick -size 1x128 "xc:${toolbar_color}" "${images_dir}/theme_toolbar.png"
        magick -size 1x80 "xc:${tab_color}" "${images_dir}/theme_tab_background.png"
    elif command -v convert &>/dev/null; then
        convert -size 1x128 "xc:${frame_color}" "${images_dir}/theme_frame.png"
        convert -size 1x128 "xc:${toolbar_color}" "${images_dir}/theme_toolbar.png"
        convert -size 1x80 "xc:${tab_color}" "${images_dir}/theme_tab_background.png"
    else
        log_warn "ImageMagick not found, skipping Brave images"
        return 0
    fi

    log_success "Brave theme images generated"
}

# Generate GTK theme using oomox-cli
generate_gtk_theme() {
    local theme_name="$1"
    local theme_dir="${THEMES_DIR}/${theme_name}"
    local oomox_file="${theme_dir}/colors-oomox"
    local gtk_dest="$HOME/.themes/${theme_name}"

    [[ ! -f "$oomox_file" ]] && return 0

    if ! command -v oomox-cli &>/dev/null; then
        log_warn "oomox-cli not found, skipping GTK theme generation"
        return 0
    fi

    log_info "Generating GTK theme with oomox..."

    # Generate GTK theme (suppress verbose output)
    # Ensure gtk-4.0 symlink exists after generation
    oomox-cli -o "$theme_name" -t "$HOME/.themes" "$oomox_file" >/dev/null 2>&1 || {
        log_warn "oomox-cli failed"
        return 0
    }

    if [[ -d "$gtk_dest" ]]; then
        log_success "GTK theme generated: $gtk_dest"

        # Ensure gtk-4.0 symlink exists (oomox doesn't always create it)
        if [[ -d "${gtk_dest}/gtk-3.20" && ! -e "${gtk_dest}/gtk-4.0" ]]; then
            ln -sf gtk-3.20 "${gtk_dest}/gtk-4.0"
            log_success "Created gtk-4.0 symlink"
        fi

        # Generate GTK4 CSS using base16 if available
        local gtk4_template="/opt/oomox/plugins/base16/templates/gtk4-oodwaita/templates/gtk4-libadwaita1.7.2.mustache"
        if [[ -f "$gtk4_template" ]]; then
            local gtk4_dir="${gtk_dest}/gtk-4.0"
            mkdir -p "$gtk4_dir"

            local gtk4_css
            gtk4_css=$(python3 /opt/oomox/plugins/base16/cli.py "$gtk4_template" "$oomox_file" 2>/dev/null | grep -v "^Import Colors" || true)

            if [[ -n "$gtk4_css" ]]; then
                echo "$gtk4_css" > "${gtk4_dir}/gtk.css"

                # Append overrides if they exist
                local gtk4_overrides="${theme_dir}/gtk4-overrides.css"
                [[ -f "$gtk4_overrides" ]] && cat "$gtk4_overrides" >> "${gtk4_dir}/gtk.css"

                # Clean up oomox GTK3 files that cause GTK4 warnings
                rm -f "${gtk4_dir}/gtk.gresource" "${gtk4_dir}/gtk.gresource.xml" "${gtk4_dir}/gtk-dark.css"
                rm -rf "${gtk4_dir}/dist"

                log_success "GTK4 theme generated with libadwaita support"
            fi
        fi
    fi
}

# Main: process all templates for a theme
main() {
    local theme_name="$1"

    if [[ -z "$theme_name" ]]; then
        echo "Usage: $0 <theme-name>"
        echo ""
        echo "Process all templates for a theme, replacing {{placeholders}} with colors"
        exit 1
    fi

    local theme_dir="${THEMES_DIR}/${theme_name}"
    local colors_file="${theme_dir}/colors.yaml"

    if [[ ! -d "$theme_dir" ]]; then
        log_error "Theme directory not found: $theme_dir"
        exit 1
    fi

    if [[ ! -f "$colors_file" ]]; then
        log_error "colors.yaml not found: $colors_file"
        exit 1
    fi

    echo "Processing templates for: ${theme_name}"
    echo ""

    local count=0

    # Process all .template files
    while IFS= read -r -d '' template; do
        local name=$(basename "${template%.template}")
        log_info "  $name"
        process_template "$template" "$theme_name"
        ((count++)) || true
    done < <(find "$TEMPLATES_DIR" -name "*.template" -type f -print0 2>/dev/null)

    echo ""

    # Generate oomox colors file
    generate_oomox_file "$theme_name"

    # Generate Brave theme images
    generate_brave_images "$theme_name"

    # Generate GTK theme
    generate_gtk_theme "$theme_name"

    echo ""
    log_success "Processed ${count} templates for ${theme_name}"
}

main "$@"
