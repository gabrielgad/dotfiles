# Themix Color Schema v1.0

All themes must follow this standardized schema for template compatibility.

## Required Sections

```yaml
metadata:
  name: "theme-name"
  wallpaper: "/path/to/wallpaper.jpg"
  generated: "ISO-8601 timestamp"
  generator: "generator-name"

text:
  primary: '#HEXCOLOR'      # Main text color (brightest)
  primary_rgb: HEXNOHASH    # Without # for templates needing raw hex
  secondary: '#HEXCOLOR'    # Secondary text
  secondary_rgb: HEXNOHASH
  tertiary: '#HEXCOLOR'     # Tertiary/dimmed text
  tertiary_rgb: HEXNOHASH

surface:
  primary: '#HEXCOLOR'      # Main background (darkest)
  primary_rgb: HEXNOHASH
  primary_rgba: 'rgba(r, g, b, 0.95)'  # For transparency
  secondary: '#HEXCOLOR'    # Slightly lighter bg
  secondary_rgb: HEXNOHASH
  tertiary: '#HEXCOLOR'     # Even lighter bg
  tertiary_rgb: HEXNOHASH

accent:
  primary: '#HEXCOLOR'      # Main accent/highlight
  primary_rgb: HEXNOHASH
  secondary: '#HEXCOLOR'    # Secondary accent
  secondary_rgb: HEXNOHASH
  tertiary: '#HEXCOLOR'     # Tertiary accent
  tertiary_rgb: HEXNOHASH

semantic:
  active: '#HEXCOLOR'       # Active/selected state
  active_rgb: HEXNOHASH
  inactive: '#HEXCOLOR'     # Inactive state
  inactive_rgb: HEXNOHASH
  hover: '#HEXCOLOR'        # Hover state (CRITICAL for GTK)
  hover_rgb: HEXNOHASH
  focus: '#HEXCOLOR'        # Focus indicator
  focus_rgb: HEXNOHASH

border:
  primary: '#HEXCOLOR'      # Main borders
  primary_rgb: HEXNOHASH
  subtle: '#HEXCOLOR'       # Subtle/inactive borders
  subtle_rgb: HEXNOHASH
  accent: '#HEXCOLOR'       # Accent borders
  accent_rgb: HEXNOHASH

terminal:
  color0: '#HEXCOLOR'       # Black
  color1: '#HEXCOLOR'       # Red
  color2: '#HEXCOLOR'       # Green
  color3: '#HEXCOLOR'       # Yellow
  color4: '#HEXCOLOR'       # Blue
  color5: '#HEXCOLOR'       # Magenta
  color6: '#HEXCOLOR'       # Cyan
  color7: '#HEXCOLOR'       # White
  color8: '#HEXCOLOR'       # Bright Black
  color9: '#HEXCOLOR'       # Bright Red
  color10: '#HEXCOLOR'      # Bright Green
  color11: '#HEXCOLOR'      # Bright Yellow
  color12: '#HEXCOLOR'      # Bright Blue
  color13: '#HEXCOLOR'      # Bright Magenta
  color14: '#HEXCOLOR'      # Bright Cyan
  color15: '#HEXCOLOR'      # Bright White

oomox:
  name: "theme-name"
  bg: 'HEXNOHASH'
  fg: HEXNOHASH
  menu_bg: 'HEXNOHASH'
  menu_fg: HEXNOHASH
  sel_bg: HEXNOHASH
  sel_fg: 'HEXNOHASH'
  txt_bg: 'HEXNOHASH'
  txt_fg: HEXNOHASH
  btn_bg: HEXNOHASH
  btn_fg: HEXNOHASH
  hdr_btn_bg: HEXNOHASH
  hdr_btn_fg: HEXNOHASH
  wm_border_focus: HEXNOHASH
  wm_border_unfocus: HEXNOHASH
  icons_light_folder: HEXNOHASH
  icons_medium: HEXNOHASH
  icons_dark: 'HEXNOHASH'
  roundness: 4
  spacing: 3
  gradient: 0.0
  gtk3_generate_dark: 'True'
```

## Waybar Theming (Portable)

For portable waybar theming, use the provided base stylesheet:

```css
/* ~/.config/waybar/style.css */
@import "theme.css";           /* Generated theme colors */
@import "waybar-base.css";     /* Base styles using theme vars */

/* Your custom overrides below */
```

**Core variables** (all you need for waybar-base.css):
- `@accent` - Module text color
- `@background` - Module backgrounds
- `@foreground` - Default text
- `@hover` - Hover states
- `@active` - Active/selected states
- `@urgent` - Warning states

Copy the base stylesheet:
```bash
cp ~/.config/themes/templates/waybar-base.css ~/.config/waybar/
```

## Per-Theme Color Overrides

Create an `overrides.yaml` in any theme directory to inject or override colors.
These are merged on top of extracted colors during template processing.

```yaml
# ~/.config/themes/<theme-name>/overrides.yaml
# Only specify values you want to override/inject

accent:
  primary: '#ff6b6b'      # Inject a coral accent not found in wallpaper
  secondary: '#4ecdc4'    # Custom teal

# Add entirely new color sections
custom:
  brand: '#1da1f2'
  warning: '#ffcc00'

# Override specific terminal colors
terminal:
  color1: '#ff5555'       # Always use this red
```

**Usage:**
1. Generate theme normally: `nu generate-theme.nu wallpaper.jpg mytheme`
2. Create `~/.config/themes/mytheme/overrides.yaml` with your custom colors
3. Regenerate: `nu generate-theme.nu mytheme` (reads overrides automatically)

Overrides are deep-merged: only specified values change, everything else keeps extracted colors.

## Optional Sections

```yaml
rgb:
  # For apps needing RGB arrays (e.g., Brave)
  background: [r, g, b]
  foreground: [r, g, b]
  accent_primary: [r, g, b]
  accent_secondary: [r, g, b]
```

## Template Placeholder Reference

Templates use `{{section.key}}` syntax:
- `{{text.primary}}` - Main text color with #
- `{{text.primary_rgb}}` - Main text without #
- `{{surface.primary}}` - Main background
- `{{semantic.hover}}` - Hover state (GTK critical)

### Override Syntax

For user-customizable placeholders, templates use `{{key|default}}`:
- `{{gpu|text.primary}}` - Uses user-mappings override for "gpu" or falls back to text.primary
- See `user-mappings.yaml` to customize module colors

## Brave/Chrome Theme Setup

Brave themes require a one-time setup to auto-load on browser launch.

### Required: Desktop Launcher Override

Create `~/.local/share/applications/brave-browser.desktop`:

```ini
[Desktop Entry]
Version=1.0
Name=Brave Web Browser
Exec=brave --load-extension=$HOME/.config/brave-theme-current %U
Terminal=false
Type=Application
Icon=brave-browser
Categories=Network;WebBrowser;
StartupWMClass=brave-browser
```

This makes Brave load the theme symlink on every launch. The symlink is auto-updated by `apply-theme`.

### How It Works

1. `process-templates.nu` generates `brave-theme/manifest.json` and images
2. `apply-theme` symlinks current theme's `brave-theme/` to `~/.config/brave-theme-current`
3. Brave's `--load-extension` flag loads from that symlink
4. Theme changes require Brave restart to take effect

### RGB Section (Required for Brave)

The `rgb:` section provides `[r, g, b]` arrays for Brave's manifest:

```yaml
rgb:
  background: [14, 9, 29]
  foreground: [17, 174, 179]
  accent_primary: [200, 233, 103]
  accent_secondary: [226, 3, 66]
  accent_tertiary: [166, 2, 52]
  accent_quaternary: [17, 174, 179]  # Same as foreground
  active: [42, 59, 60]
  hover: [42, 21, 60]
  frame: [26, 15, 46]
  urgent: [166, 2, 52]
```

New themes auto-generate this via `extract-colors.nu`. For manually created themes, add this section.
