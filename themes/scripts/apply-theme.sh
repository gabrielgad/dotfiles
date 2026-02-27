#!/usr/bin/env bash
#
# Themix Theme Applier
# Apply theme by creating symlinks, copying configs, and restarting services
# Requires: bash, python3, PyYAML

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="${THEMES_DIR:-$HOME/.config/themes}"

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

# Get value from YAML
yaml_get() {
    local yaml_file="$1"
    local key_path="$2"

    python3 -c "
import yaml
import sys
try:
    with open('$yaml_file', 'r') as f:
        data = yaml.safe_load(f)
    keys = '$key_path'.split('.')
    value = data
    for key in keys:
        if isinstance(value, dict) and key in value:
            value = value[key]
        else:
            sys.exit(1)
    print(value)
except:
    sys.exit(1)
" 2>/dev/null
}

# Create symlink (removes existing)
safe_symlink() {
    local src="$1"
    local dest="$2"

    [[ ! -f "$src" ]] && return 1

    local dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"

    [[ -e "$dest" || -L "$dest" ]] && rm -f "$dest"
    ln -sf "$src" "$dest"
    return 0
}

# Create symlink for directory (removes existing)
safe_symlink_dir() {
    local src="$1"
    local dest="$2"

    [[ ! -d "$src" ]] && return 1

    local dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"

    [[ -e "$dest" || -L "$dest" ]] && rm -rf "$dest"
    ln -sf "$src" "$dest"
    return 0
}

# Copy file (removes existing)
safe_copy() {
    local src="$1"
    local dest="$2"

    [[ ! -f "$src" ]] && return 1

    local dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"

    [[ -e "$dest" ]] && rm -f "$dest"
    cp "$src" "$dest"
    return 0
}

# Update a line in a config file
update_setting() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"

    [[ ! -f "$file" ]] && return 1

    if grep -q "^${pattern}" "$file"; then
        sed -i "s|^${pattern}.*|${replacement}|" "$file"
    else
        echo "$replacement" >> "$file"
    fi
}

# Apply core symlinks
apply_symlinks() {
    local theme_dir="$1"
    local theme_name="$2"

    echo "Applying symlinks..."

    # Hyprland theme
    safe_symlink "${theme_dir}/hyprland.conf" "$HOME/.config/hypr/theme.conf" && \
        log_success "hyprland.conf -> ~/.config/hypr/theme.conf"

    # Waybar
    safe_symlink "${theme_dir}/waybar.css" "$HOME/.config/waybar/theme.css" && \
        log_success "waybar.css -> ~/.config/waybar/theme.css"

    safe_symlink "${theme_dir}/waybar-themix.css" "$HOME/.config/waybar/themix.css" && \
        log_success "waybar-themix.css -> ~/.config/waybar/themix.css"

    # Kitty
    safe_symlink "${theme_dir}/kitty.conf" "$HOME/.config/kitty/theme.conf" && \
        log_success "kitty.conf -> ~/.config/kitty/theme.conf"

    # Btop
    safe_symlink "${theme_dir}/btop.theme" "$HOME/.config/btop/themes/current.theme" && \
        log_success "btop.theme -> ~/.config/btop/themes/current.theme"

    # Hyprlock
    safe_symlink "${theme_dir}/hyprlock.conf" "$HOME/.config/hypr/hyprlock-theme.conf" && \
        log_success "hyprlock.conf -> ~/.config/hypr/hyprlock-theme.conf"

    # Brave theme (directory symlink)
    safe_symlink_dir "${theme_dir}/brave-theme" "$HOME/.config/brave-theme-current" && \
        log_success "brave-theme -> ~/.config/brave-theme-current (restart Brave to apply)"

    # Niri (if using)
    safe_symlink "${theme_dir}/niri.kdl" "$HOME/.config/niri/theme.kdl" && \
        log_success "niri.kdl -> ~/.config/niri/theme.kdl"
}

# Apply copies (files that need to be actual copies, not symlinks)
apply_copies() {
    local theme_dir="$1"

    echo ""
    echo "Applying copies..."

    # Wofi
    safe_copy "${theme_dir}/wofi.css" "$HOME/.config/wofi/style.css" && \
        log_success "wofi.css -> ~/.config/wofi/style.css"

    # Wlogout
    safe_copy "${theme_dir}/wlogout.css" "$HOME/.config/wlogout/style.css" && \
        log_success "wlogout.css -> ~/.config/wlogout/style.css"

    # Mako
    safe_copy "${theme_dir}/mako.ini" "$HOME/.config/mako/config" && \
        log_success "mako.ini -> ~/.config/mako/config"

    # Rofi
    safe_copy "${theme_dir}/rofi.rasi" "$HOME/.config/rofi/theme.rasi" && \
        log_success "rofi.rasi -> ~/.config/rofi/theme.rasi"
}

# Update GTK settings
apply_gtk_settings() {
    local theme_name="$1"

    echo ""
    echo "Applying GTK settings..."

    # GTK3 settings.ini
    local gtk3_settings="$HOME/.config/gtk-3.0/settings.ini"
    mkdir -p "$(dirname "$gtk3_settings")"
    if [[ -f "$gtk3_settings" ]]; then
        update_setting "$gtk3_settings" "gtk-theme-name=" "gtk-theme-name=${theme_name}"
    else
        cat > "$gtk3_settings" << EOF
[Settings]
gtk-theme-name=${theme_name}
EOF
    fi
    log_success "Updated GTK3 settings.ini"

    # gsettings
    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface gtk-theme "$theme_name" 2>/dev/null && \
            log_success "Updated gsettings gtk-theme"
    fi

    # Hyprland environment
    local hypr_env="$HOME/.config/hypr/config/environment.conf"
    if [[ -f "$hypr_env" ]]; then
        update_setting "$hypr_env" "envd = GTK_THEME," "envd = GTK_THEME,${theme_name}"
        log_success "Updated Hyprland GTK_THEME environment"
    fi

    # Update GTK_THEME in running Hyprland
    if command -v hyprctl &>/dev/null; then
        hyprctl keyword envd "GTK_THEME,${theme_name}" &>/dev/null || true
    fi
}

# Apply GTK4 user CSS overrides
apply_gtk_overrides() {
    local theme_dir="$1"

    # GTK4 overrides
    local gtk4_overrides="${theme_dir}/gtk4-overrides.css"
    if [[ -f "$gtk4_overrides" ]]; then
        mkdir -p "$HOME/.config/gtk-4.0"
        local gtk4_dest="$HOME/.config/gtk-4.0/gtk.css"
        [[ -e "$gtk4_dest" || -L "$gtk4_dest" ]] && rm -f "$gtk4_dest"
        ln -sf "$gtk4_overrides" "$gtk4_dest"
        log_success "GTK4 user CSS applied"
    fi

    # GTK3 overrides
    local gtk3_overrides="${theme_dir}/gtk3-overrides.css"
    if [[ -f "$gtk3_overrides" ]]; then
        mkdir -p "$HOME/.config/gtk-3.0"
        local gtk3_dest="$HOME/.config/gtk-3.0/gtk.css"
        [[ -e "$gtk3_dest" || -L "$gtk3_dest" ]] && rm -f "$gtk3_dest"
        ln -sf "$gtk3_overrides" "$gtk3_dest"
        log_success "GTK3 user CSS applied"
    fi
}

# Apply optional app themes
apply_optional_themes() {
    local theme_dir="$1"
    local theme_name="$2"

    echo ""
    echo "Applying optional app themes..."

    # Starship prompt
    if [[ -f "${theme_dir}/starship.toml" ]]; then
        safe_symlink "${theme_dir}/starship.toml" "$HOME/.config/starship.toml" && \
            log_success "starship theme applied"
    fi

    # Lazygit
    if [[ -f "${theme_dir}/lazygit.yml" ]]; then
        safe_symlink "${theme_dir}/lazygit.yml" "$HOME/.config/lazygit/config.yml" && \
            log_success "lazygit theme applied"
    fi

    # Zellij
    if [[ -f "${theme_dir}/zellij.kdl" ]]; then
        mkdir -p "$HOME/.config/zellij/themes"
        safe_symlink "${theme_dir}/zellij.kdl" "$HOME/.config/zellij/themes/themix.kdl" && \
            log_success "zellij theme applied"
    fi

    # Bottom
    if [[ -f "${theme_dir}/bottom.toml" ]]; then
        safe_symlink "${theme_dir}/bottom.toml" "$HOME/.config/bottom/bottom.toml" && \
            log_success "bottom theme applied"
    fi

    # Fastfetch
    if [[ -f "${theme_dir}/fastfetch.jsonc" ]]; then
        safe_symlink "${theme_dir}/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc" && \
            log_success "fastfetch theme applied"
    fi

    # Cava
    if [[ -f "${theme_dir}/cava.config" ]]; then
        safe_symlink "${theme_dir}/cava.config" "$HOME/.config/cava/config" && \
            log_success "cava theme applied"
    fi

    # Swaync
    if [[ -f "${theme_dir}/swaync-style.css" ]]; then
        safe_symlink "${theme_dir}/swaync-style.css" "$HOME/.config/swaync/style.css" && \
            log_success "swaync theme applied"
    fi

    # Yazi
    if [[ -f "${theme_dir}/yazi.toml" ]]; then
        mkdir -p "$HOME/.config/yazi"
        safe_copy "${theme_dir}/yazi.toml" "$HOME/.config/yazi/theme.toml" && \
            log_success "yazi theme applied"
    fi

    # Kvantum
    local kvantum_dir="${theme_dir}/kvantum/${theme_name}"
    if [[ -d "$kvantum_dir" ]]; then
        mkdir -p "$HOME/.config/Kvantum"
        local kvantum_dest="$HOME/.config/Kvantum/${theme_name}"
        [[ -e "$kvantum_dest" || -L "$kvantum_dest" ]] && rm -rf "$kvantum_dest"
        ln -sf "$kvantum_dir" "$kvantum_dest"

        # Update kvantum.kvconfig
        cat > "$HOME/.config/Kvantum/kvantum.kvconfig" << EOF
[General]
theme=${theme_name}
EOF
        log_success "Kvantum theme set to: ${theme_name}"
    fi
}

# Update current symlink
update_current_link() {
    local theme_dir="$1"
    local current_link="${THEMES_DIR}/current"

    [[ -e "$current_link" || -L "$current_link" ]] && rm -f "$current_link"
    ln -sf "$theme_dir" "$current_link"
    log_success "Updated 'current' symlink"
}

# Set wallpaper
set_wallpaper() {
    local theme_dir="$1"

    # Find wallpaper file
    local wallpaper=""
    for ext in jpg jpeg png; do
        if [[ -f "${theme_dir}/wallpaper.${ext}" ]]; then
            wallpaper="${theme_dir}/wallpaper.${ext}"
            break
        fi
    done

    # Check backgrounds directory
    if [[ -z "$wallpaper" && -d "${theme_dir}/backgrounds" ]]; then
        wallpaper=$(find "${theme_dir}/backgrounds" -type f \( -name "*.jpg" -o -name "*.png" \) | head -1)
    fi

    if [[ -n "$wallpaper" ]]; then
        echo ""
        log_info "Setting wallpaper: $(basename "$wallpaper")"

        # Kill existing swaybg
        pkill swaybg 2>/dev/null || true
        sleep 0.2

        # Start new swaybg based on compositor
        if command -v hyprctl &>/dev/null && pgrep -x Hyprland &>/dev/null; then
            hyprctl dispatch exec "swaybg -o '*' -i '$wallpaper' -m fill" &>/dev/null
        elif command -v niri &>/dev/null && pgrep -x niri &>/dev/null; then
            niri msg action spawn -- swaybg -i "$wallpaper" -m fill
        else
            swaybg -i "$wallpaper" -m fill &
            disown
        fi

        log_success "Wallpaper set"
    fi
}

# Install nvim colorscheme from theme
apply_nvim_colorscheme() {
    local theme_dir="$1"
    local theme_name="$2"
    local nvim_theme="${theme_dir}/nvim.lua"
    local nvim_config="$HOME/.config/nvim"

    [[ ! -f "$nvim_theme" ]] && return 0

    echo ""
    log_info "Installing nvim colorscheme..."

    # Clean old colorschemes (only one active at a time)
    local colors_dir="${nvim_config}/colors"
    for old_vim in "${colors_dir}"/*.vim; do
        [[ ! -f "$old_vim" ]] && continue
        local old_name
        old_name="$(basename "$old_vim" .vim)"
        rm -f "$old_vim"
        rm -rf "${nvim_config}/lua/${old_name}"
    done

    # Install lua module
    local lua_dir="${nvim_config}/lua/${theme_name}"
    mkdir -p "$lua_dir"
    cp "$nvim_theme" "${lua_dir}/init.lua"

    # Create vim wrapper (init.lua auto-discovers from colors/)
    mkdir -p "$colors_dir"
    echo "\" ${theme_name} colorscheme wrapper
lua require('${theme_name}').setup()" > "${colors_dir}/${theme_name}.vim"

    log_success "nvim colorscheme '${theme_name}' installed"
}

# Niri colors are applied via theme.kdl symlink + include directive in config.kdl
# No need to sed-edit config.kdl anymore
apply_niri_colors() {
    log_info "Niri colors applied via theme.kdl include"
}

# Reload niri config
reload_niri() {
    if command -v niri &>/dev/null && pgrep -x niri &>/dev/null; then
        echo ""
        log_info "Reloading Niri..."
        niri msg action load-config-file &>/dev/null && \
            log_success "Niri reloaded"
    fi
}

# Restart waybar
restart_waybar() {
    echo ""
    log_info "Restarting waybar..."

    killall -q waybar 2>/dev/null || true
    sleep 0.5

    if command -v hyprctl &>/dev/null && pgrep -x Hyprland &>/dev/null; then
        hyprctl dispatch exec "waybar > /tmp/waybar.log 2>&1" &>/dev/null
    elif command -v niri &>/dev/null && pgrep -x niri &>/dev/null; then
        niri msg action spawn -- sh -c "waybar > /tmp/waybar.log 2>&1" &>/dev/null || {
            waybar > /tmp/waybar.log 2>&1 &
            disown
        }
    else
        waybar > /tmp/waybar.log 2>&1 &
        disown
    fi

    log_success "Waybar restarted"
}

# Main
main() {
    local theme_name="$1"

    if [[ -z "$theme_name" ]]; then
        echo "Usage: $0 <theme-name>"
        echo ""
        echo "Apply a theme by symlinking configs and restarting services"
        exit 1
    fi

    local theme_dir="${THEMES_DIR}/${theme_name}"

    if [[ ! -d "$theme_dir" ]]; then
        log_error "Theme not found: $theme_dir"
        exit 1
    fi

    # Check required files
    local required=("waybar-themix.css" "kitty.conf")
    for file in "${required[@]}"; do
        if [[ ! -f "${theme_dir}/${file}" ]]; then
            log_error "Missing required file: ${file}"
            log_error "Run: process-templates.sh ${theme_name}"
            exit 1
        fi
    done

    echo "Applying theme: ${theme_name}"
    echo ""

    # Re-process templates to ensure theme files match latest templates
    log_info "Refreshing templates..."
    bash "${SCRIPT_DIR}/process-templates.sh" "$theme_name"

    apply_symlinks "$theme_dir" "$theme_name"
    apply_copies "$theme_dir"
    apply_gtk_settings "$theme_name"
    apply_gtk_overrides "$theme_dir"
    apply_optional_themes "$theme_dir" "$theme_name"
    apply_nvim_colorscheme "$theme_dir" "$theme_name"
    apply_niri_colors "$theme_dir"
    update_current_link "$theme_dir"

    # Restart services
    sleep 0.1
    restart_waybar
    set_wallpaper "$theme_dir"
    reload_niri

    echo ""
    log_success "Theme '${theme_name}' applied successfully!"
}

main "$@"
