# Themix - Wallpaper-Based Theme Generator

Themix extracts colors from wallpapers and generates consistent themes across your Linux desktop applications.

## Features

- **Automatic color extraction** from any wallpaper using ImageMagick
- **Weighted scoring algorithm** - Balances color saturation with pixel prevalence
- **WCAG contrast checking** - Ensures readable accent colors
- **Multi-app support**: waybar, kitty, alacritty, ghostty, btop, hyprland, hyprlock, rofi, wofi, wlogout, GTK, Qt/Kvantum, Brave browser, nvim

## Dependencies

### Required
- **nushell** (`nu`) - Script runtime
- **ImageMagick** (`magick`) - Color extraction

### Optional (for specific features)
| Dependency | Purpose | Install (Arch) |
|------------|---------|----------------|
| `oomox-cli` | GTK theme generation | `yay -S themix-theme-oomox-git` |
| `kvantummanager` | Qt/Kvantum themes | `pacman -S kvantum` |
| `swaybg` | Wallpaper setting (Wayland) | `pacman -S swaybg` |
| `gsettings` | GTK settings for GNOME/GTK apps | `pacman -S glib2` |
| `hyprctl` | Hyprland compositor integration | `pacman -S hyprland` |
| `niri` | Niri compositor integration | `pacman -S niri` |
| `spicetify-cli` | Spotify theming | `yay -S spicetify-cli` |

## Installation

```bash
# Clone the repo
git clone https://github.com/gabrielgad/themix.git
cd themix

# Run the installer
nu install.nu

# Or install with optional dependencies
nu install.nu --install-optional
```

## Quick Start

```bash
# 1. Extract colors from a wallpaper
nu ~/.config/themes/scripts/extract-colors.nu ~/Pictures/wallpaper.jpg mytheme

# 2. Generate theme files from templates
nu ~/.config/themes/scripts/generate-theme.nu mytheme

# 3. Apply the theme
nu ~/.config/themes/operations/apply-theme mytheme
```

## Directory Structure

```
~/.config/themes/
├── scripts/           # Core scripts
│   ├── extract-colors.nu    # Color extraction
│   ├── generate-theme.nu    # Theme generation
│   └── process-templates.nu # Template processing
├── templates/         # App-specific templates
│   ├── waybar.css.template
│   ├── kitty.conf.template
│   ├── nvim.lua.template
│   └── ...
├── operations/        # Theme application scripts
│   ├── apply-theme
│   └── ...
├── pure/              # Pure helper functions
├── <theme-name>/      # Generated themes
│   ├── colors.yaml    # Extracted color palette
│   ├── wallpaper.jpg  # Symlink to source
│   ├── waybar.css     # Generated configs
│   └── ...
└── current -> <theme> # Symlink to active theme
```

## Color Extraction Algorithm

The algorithm uses weighted scoring to select accent colors:

```
score = saturation × √pixel_count
```

This ensures colors that are both **vibrant** and **prevalent** in the image are selected as accents, rather than small highly-saturated details or large desaturated backgrounds.

### Filters
- **Saturation > 0.3** - Filters out desaturated backgrounds
- **Luminance 0.12-0.85** - Filters very dark/light colors
- **Contrast check** - Adjusts colors to meet WCAG 4.5:1 ratio

## Customization

### Per-Theme Overrides

Create `overrides.yaml` in a theme directory to override extracted colors:

```yaml
# ~/.config/themes/mytheme/overrides.yaml
accent:
  primary: '#ff6600'
  secondary: '#0066ff'
```

### User Mappings

Create `user-mappings.yaml` to customize which colors map to which app elements:

```yaml
# ~/.config/themes/user-mappings.yaml
waybar:
  cpu: accent.secondary
  memory: accent.tertiary
```

## Adding New App Templates

1. Create a template in `templates/`:
   ```
   templates/myapp.conf.template
   ```

2. Use `{{color.path}}` placeholders:
   ```
   background = {{surface.primary}}
   foreground = {{text.primary}}
   accent = {{accent.primary}}
   ```

3. Available color paths (see SCHEMA.md for full list):
   - `surface.primary`, `surface.secondary`, etc.
   - `text.primary`, `text.secondary`, etc.
   - `accent.primary`, `accent.secondary`, etc.
   - `terminal.color0` through `terminal.color15`

4. Add apply logic to `operations/apply-theme` if needed

## Neovim Colorscheme Installation

The nvim installer auto-detects your config type (init.lua or init.vim):

```bash
# Install colorscheme (manual activation)
nu ~/.config/themes/operations/install-nvim-colorscheme mytheme

# Install and set as default (updates your init.lua/init.vim)
nu ~/.config/themes/operations/install-nvim-colorscheme mytheme --set-default
```

This creates:
- `~/.config/nvim/lua/<theme>/init.lua` - Lua colorscheme module
- `~/.config/nvim/colors/<theme>.vim` - Vim wrapper for `:colorscheme` command

Works with vanilla nvim, lazy.nvim, packer, and vim-plug setups.

## Supported Applications

| App | Template | Notes |
|-----|----------|-------|
| waybar | waybar.css.template | CSS variables |
| kitty | kitty.conf.template | Terminal colors |
| alacritty | alacritty.toml.template | Terminal colors |
| ghostty | ghostty.conf.template | Terminal colors |
| btop | btop.theme.template | System monitor |
| hyprland | hyprland.conf.template | Border colors |
| hyprlock | hyprlock.conf.template | Lock screen |
| niri | niri.kdl.template | Border colors |
| rofi | rofi.rasi.template | Launcher |
| wofi | wofi.css.template | Launcher |
| wlogout | wlogout.css.template | Logout menu |
| nvim | nvim.lua.template | Neovim colorscheme |
| yazi | yazi.toml.template | TUI file manager |
| GTK | colors-oomox.template | Via oomox-cli |
| Kvantum | kvantum/*.template | Qt theming |
| Brave | brave-theme/*.template | Browser theme |

## License

MIT
