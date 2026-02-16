#!/usr/bin/env python3
"""
Themix Color Extractor
Extracts dominant colors from wallpaper and generates colors.yaml
Portable Python implementation (requires: python3, Pillow, PyYAML)
"""

import sys
import argparse
from pathlib import Path
from collections import defaultdict
from datetime import datetime
import math
import os

try:
    import yaml
except ImportError:
    print("Error: PyYAML required. Install: pip install PyYAML", file=sys.stderr)
    sys.exit(1)

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow required. Install: pip install Pillow", file=sys.stderr)
    sys.exit(1)


# =============================================================================
# Color Conversion Utilities
# =============================================================================

def rgb_to_hsl(r, g, b):
    """Convert RGB (0-255) to HSL (0-1)"""
    r, g, b = r / 255.0, g / 255.0, b / 255.0
    max_val = max(r, g, b)
    min_val = min(r, g, b)
    diff = max_val - min_val
    l = (max_val + min_val) / 2.0

    if diff == 0:
        h = s = 0
    else:
        s = diff / (2.0 - max_val - min_val) if l > 0.5 else diff / (max_val + min_val)
        if max_val == r:
            h = (g - b) / diff + (6 if g < b else 0)
        elif max_val == g:
            h = (b - r) / diff + 2
        else:
            h = (r - g) / diff + 4
        h /= 6.0

    return h, s, l


def hsl_to_rgb(h, s, l):
    """Convert HSL (0-1) to RGB (0-255)"""
    def hue_to_rgb(p, q, t):
        if t < 0: t += 1
        if t > 1: t -= 1
        if t < 1/6: return p + (q - p) * 6 * t
        if t < 1/2: return q
        if t < 2/3: return p + (q - p) * (2/3 - t) * 6
        return p

    if s == 0:
        r = g = b = l
    else:
        q = l * (1 + s) if l < 0.5 else l + s - l * s
        p = 2 * l - q
        r = hue_to_rgb(p, q, h + 1/3)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1/3)

    return (int(r * 255), int(g * 255), int(b * 255))


def rgb_to_hex(rgb):
    """Convert RGB tuple to hex string with #"""
    return '#{:02X}{:02X}{:02X}'.format(*rgb)


def rgb_to_hex_raw(rgb):
    """Convert RGB tuple to hex string without #"""
    return '{:02X}{:02X}{:02X}'.format(*rgb)


def rgb_to_rgba(rgb, alpha=0.95):
    """Convert RGB to rgba() string"""
    return f"rgba({rgb[0]}, {rgb[1]}, {rgb[2]}, {alpha})"


def adjust_lightness(rgb, factor):
    """Adjust lightness of a color by factor (>1 lighter, <1 darker)"""
    h, s, l = rgb_to_hsl(*rgb)
    l = max(0, min(1, l * factor))
    return hsl_to_rgb(h, s, l)


def set_lightness(rgb, target_l):
    """Set lightness to specific value"""
    h, s, _ = rgb_to_hsl(*rgb)
    return hsl_to_rgb(h, s, target_l)


def set_saturation(rgb, target_s):
    """Set saturation to specific value"""
    h, _, l = rgb_to_hsl(*rgb)
    return hsl_to_rgb(h, target_s, l)


def calculate_luminance(rgb):
    """Calculate relative luminance (0.0 = black, 1.0 = white)"""
    r, g, b = rgb[0] / 255.0, rgb[1] / 255.0, rgb[2] / 255.0
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(bg_rgb, fg_rgb):
    """Calculate WCAG contrast ratio between two colors"""
    bg_lum = calculate_luminance(bg_rgb)
    fg_lum = calculate_luminance(fg_rgb)
    lighter = max(bg_lum, fg_lum)
    darker = min(bg_lum, fg_lum)
    return (lighter + 0.05) / (darker + 0.05)


def ensure_contrast(fg_rgb, bg_rgb, min_ratio=4.5):
    """Adjust foreground color lightness to achieve minimum contrast ratio"""
    current_ratio = contrast_ratio(bg_rgb, fg_rgb)
    if current_ratio >= min_ratio:
        return fg_rgb

    h, s, l = rgb_to_hsl(*fg_rgb)
    bg_lum = calculate_luminance(bg_rgb)

    # Try increasing lightness in steps (for dark backgrounds)
    if bg_lum < 0.5:
        for target_l in [0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9]:
            test_rgb = hsl_to_rgb(h, s, target_l)
            if contrast_ratio(bg_rgb, test_rgb) >= min_ratio:
                return test_rgb
    else:
        # For light backgrounds, try decreasing lightness
        for target_l in [0.4, 0.35, 0.3, 0.25, 0.2, 0.15, 0.1]:
            test_rgb = hsl_to_rgb(h, s, target_l)
            if contrast_ratio(bg_rgb, test_rgb) >= min_ratio:
                return test_rgb

    # Return best attempt (maximum lightness adjustment)
    return hsl_to_rgb(h, s, 0.85 if bg_lum < 0.5 else 0.15)


# =============================================================================
# Color Extraction
# =============================================================================

def extract_colors(image_path, num_colors=5):
    """
    Extract dominant colors from image using weighted scoring.
    Score = saturation * sqrt(pixel_count) - prioritizes vibrant colors
    """
    img = Image.open(image_path)
    img.thumbnail((300, 300))  # Resize for performance
    img = img.convert('RGB')

    # Count pixel frequencies
    color_counts = defaultdict(int)
    for pixel in img.getdata():
        # Quantize to reduce unique colors
        quantized = (pixel[0] // 8 * 8, pixel[1] // 8 * 8, pixel[2] // 8 * 8)
        color_counts[quantized] += 1

    # Score colors by saturation * sqrt(count)
    scored_colors = []
    for color, count in color_counts.items():
        h, s, l = rgb_to_hsl(*color)
        # Filter: reasonable saturation and luminance
        if s > 0.15 and 0.10 < l < 0.90:
            score = s * math.sqrt(count)
            scored_colors.append((score, color, count, h, s, l))

    # Sort by score descending
    scored_colors.sort(reverse=True, key=lambda x: x[0])

    # Extract diverse colors (different hues)
    selected = []
    for score, color, count, h, s, l in scored_colors:
        # Check hue distance from already selected colors
        is_different = True
        for _, sel_color, _, sel_h, _, _ in selected:
            hue_diff = min(abs(h - sel_h), 1 - abs(h - sel_h))
            if hue_diff < 0.10:  # Too similar in hue (~36°)
                is_different = False
                break
        if is_different:
            selected.append((score, color, count, h, s, l))
            if len(selected) >= num_colors:
                break

    # Fill remaining slots with highest scored colors
    if len(selected) < num_colors:
        for item in scored_colors:
            if item not in selected:
                selected.append(item)
                if len(selected) >= num_colors:
                    break

    return [item[1] for item in selected]


def determine_theme_mode(colors):
    """Determine if wallpaper is light or dark overall"""
    total_lightness = sum(rgb_to_hsl(*c)[2] for c in colors) / len(colors)
    return 'light' if total_lightness > 0.5 else 'dark'


# =============================================================================
# Color Scheme Generation
# =============================================================================

def generate_surfaces(accent_color, mode='dark'):
    """Generate surface colors from accent"""
    h, s, _ = rgb_to_hsl(*accent_color)

    if mode == 'dark':
        # Dark mode: very dark surfaces with hint of accent hue
        return {
            'primary': hsl_to_rgb(h, s * 0.15, 0.07),
            'secondary': hsl_to_rgb(h, s * 0.18, 0.10),
            'tertiary': hsl_to_rgb(h, s * 0.20, 0.14),
            'quaternary': hsl_to_rgb(h, s * 0.12, 0.22),
            'quinary': hsl_to_rgb(h, s * 0.10, 0.28),
        }
    else:
        # Light mode
        return {
            'primary': hsl_to_rgb(h, s * 0.10, 0.96),
            'secondary': hsl_to_rgb(h, s * 0.12, 0.92),
            'tertiary': hsl_to_rgb(h, s * 0.15, 0.88),
            'quaternary': hsl_to_rgb(h, s * 0.08, 0.82),
            'quinary': hsl_to_rgb(h, s * 0.06, 0.76),
        }


def generate_text_colors(surface_primary, mode='dark'):
    """Generate text colors with good contrast against surface"""
    h, s, _ = rgb_to_hsl(*surface_primary)

    if mode == 'dark':
        return {
            'primary': hsl_to_rgb(h, s * 0.20, 0.92),
            'secondary': hsl_to_rgb(h, s * 0.15, 0.82),
            'tertiary': hsl_to_rgb(h, s * 0.10, 0.72),
            'quaternary': hsl_to_rgb(h, s * 0.08, 0.58),
            'quinary': hsl_to_rgb(h, s * 0.05, 0.48),
        }
    else:
        return {
            'primary': hsl_to_rgb(h, s * 0.20, 0.10),
            'secondary': hsl_to_rgb(h, s * 0.15, 0.25),
            'tertiary': hsl_to_rgb(h, s * 0.10, 0.40),
            'quaternary': hsl_to_rgb(h, s * 0.08, 0.55),
            'quinary': hsl_to_rgb(h, s * 0.05, 0.65),
        }


def semantic_color(base_hue, theme_hue, tint, saturation, lightness):
    """Generate ANSI color blended toward theme hue.
    base_hue: standard ANSI hue (0-1 scale, e.g. 0=red, 1/3=green)
    theme_hue: accent hue to tint toward (0-1 scale)
    tint: 0.0=pure ANSI, 1.0=fully theme colored
    """
    hue_diff = theme_hue - base_hue
    if hue_diff > 0.5: hue_diff -= 1.0
    elif hue_diff < -0.5: hue_diff += 1.0
    blended = base_hue + hue_diff * tint
    if blended < 0: blended += 1.0
    elif blended >= 1.0: blended -= 1.0
    return hsl_to_rgb(blended, saturation, lightness)


def generate_terminal_colors(accents, surfaces, texts, mode='dark'):
    """Generate 16 ANSI terminal colors using multi-accent tinting.
    Each ANSI color blends toward a different accent hue for maximum variety.
    """
    while len(accents) < 4:
        accents.append(accents[-1])

    hue1 = rgb_to_hsl(*accents[0])[0]  # primary accent
    hue2 = rgb_to_hsl(*accents[1])[0]  # secondary accent
    hue3 = rgb_to_hsl(*accents[2])[0]  # tertiary accent
    hue4 = rgb_to_hsl(*accents[3])[0]  # quaternary accent
    tint = 0.35  # Warm toward theme but keep ANSI hue identity

    # Sort accent hues by proximity to each ANSI base hue.
    # Each ANSI color tints toward the nearest accent for natural mapping.
    accent_hues = [hue1, hue2, hue3, hue4]

    def nearest_accent(base_hue_deg):
        """Find the accent hue nearest to a base ANSI hue (in 0-1 scale)."""
        base = base_hue_deg / 360.0
        best = accent_hues[0]
        best_dist = 1.0
        for ah in accent_hues:
            d = min(abs(ah - base), 1 - abs(ah - base))
            if d < best_dist:
                best_dist = d
                best = ah
        return best

    return {
        'color0': surfaces['primary'],                                                  # black
        'color1': semantic_color(0/360, nearest_accent(0), tint, 0.60, 0.50),          # red
        'color2': semantic_color(120/360, nearest_accent(120), tint, 0.50, 0.48),      # green
        'color3': semantic_color(45/360, nearest_accent(45), tint, 0.60, 0.55),        # yellow
        'color4': semantic_color(220/360, nearest_accent(220), tint, 0.50, 0.50),      # blue
        'color5': semantic_color(300/360, nearest_accent(300), tint, 0.45, 0.50),      # magenta
        'color6': semantic_color(180/360, nearest_accent(180), tint, 0.45, 0.48),      # cyan
        'color7': texts['tertiary'],                                                    # white (dim)
        'color8': surfaces['tertiary'],                                                 # bright black
        'color9': semantic_color(0/360, nearest_accent(0), tint, 0.65, 0.62),          # bright red
        'color10': semantic_color(120/360, nearest_accent(120), tint, 0.55, 0.58),     # bright green
        'color11': semantic_color(50/360, nearest_accent(50), tint, 0.65, 0.65),       # bright yellow
        'color12': semantic_color(220/360, nearest_accent(220), tint, 0.55, 0.60),     # bright blue
        'color13': semantic_color(300/360, nearest_accent(300), tint, 0.50, 0.60),     # bright magenta
        'color14': semantic_color(180/360, nearest_accent(180), tint, 0.50, 0.58),     # bright cyan
        'color15': texts['primary'],                                                    # bright white
    }


def generate_oomox_colors(surfaces, texts, accents, image_name):
    """Generate oomox color scheme for GTK theme generation"""
    return {
        'name': image_name,
        'bg': rgb_to_hex_raw(surfaces['primary']),
        'fg': rgb_to_hex_raw(texts['primary']),
        'menu_bg': rgb_to_hex_raw(surfaces['primary']),
        'menu_fg': rgb_to_hex_raw(texts['primary']),
        'sel_bg': rgb_to_hex_raw(accents[0]),
        'sel_fg': rgb_to_hex_raw(surfaces['primary']),
        'txt_bg': rgb_to_hex_raw(surfaces['primary']),
        'txt_fg': rgb_to_hex_raw(texts['primary']),
        'btn_bg': rgb_to_hex_raw(accents[1] if len(accents) > 1 else accents[0]),
        'btn_fg': rgb_to_hex_raw(accents[0]),
        'hdr_btn_bg': rgb_to_hex_raw(surfaces['secondary']),
        'hdr_btn_fg': rgb_to_hex_raw(texts['primary']),
        'wm_border_focus': rgb_to_hex_raw(accents[1] if len(accents) > 1 else accents[0]),
        'wm_border_unfocus': rgb_to_hex_raw(surfaces['secondary']),
        'icons_light_folder': rgb_to_hex_raw(accents[0]),
        'icons_medium': rgb_to_hex_raw(texts['primary']),
        'icons_dark': rgb_to_hex_raw(surfaces['primary']),
        'roundness': 4,
        'spacing': 3,
        'gradient': 0.0,
        'gtk3_generate_dark': 'True',
    }


# =============================================================================
# Main Schema Builder
# =============================================================================

def build_colors_yaml(theme_name, wallpaper_path, accents, surfaces, texts, terminal, mode):
    """Build the complete colors.yaml structure"""

    # Ensure we have enough colors
    while len(accents) < 4:
        accents.append(accents[-1])

    image_name = Path(wallpaper_path).stem

    colors = {
        'metadata': {
            'name': theme_name,
            'wallpaper': str(wallpaper_path),
            'generated': datetime.now().isoformat(timespec='seconds'),
            'generator': 'themix-python-v1',
        },
        'text': {
            'primary': rgb_to_hex(texts['primary']),
            'primary_rgb': rgb_to_hex_raw(texts['primary']),
            'secondary': rgb_to_hex(texts['secondary']),
            'secondary_rgb': rgb_to_hex_raw(texts['secondary']),
            'tertiary': rgb_to_hex(texts['tertiary']),
            'tertiary_rgb': rgb_to_hex_raw(texts['tertiary']),
            'quaternary': rgb_to_hex(texts['quaternary']),
            'quaternary_rgb': rgb_to_hex_raw(texts['quaternary']),
            'quinary': rgb_to_hex(texts['quinary']),
            'quinary_rgb': rgb_to_hex_raw(texts['quinary']),
        },
        'surface': {
            'primary': rgb_to_hex(surfaces['primary']),
            'primary_rgb': rgb_to_hex_raw(surfaces['primary']),
            'primary_rgba': rgb_to_rgba(surfaces['primary'], 0.95),
            'secondary': rgb_to_hex(surfaces['secondary']),
            'secondary_rgb': rgb_to_hex_raw(surfaces['secondary']),
            'tertiary': rgb_to_hex(surfaces['tertiary']),
            'tertiary_rgb': rgb_to_hex_raw(surfaces['tertiary']),
            'quaternary': rgb_to_hex(surfaces['quaternary']),
            'quaternary_rgb': rgb_to_hex_raw(surfaces['quaternary']),
            'quinary': rgb_to_hex(surfaces['quinary']),
            'quinary_rgb': rgb_to_hex_raw(surfaces['quinary']),
        },
        'semantic': {
            'active': rgb_to_hex(accents[0]),
            'active_rgb': rgb_to_hex_raw(accents[0]),
            'active_fg': rgb_to_hex(surfaces['primary']),  # Dark text on accent bg
            'active_fg_rgb': rgb_to_hex_raw(surfaces['primary']),
            'inactive': rgb_to_hex(surfaces['tertiary']),
            'inactive_rgb': rgb_to_hex_raw(surfaces['tertiary']),
            'hover': rgb_to_hex(surfaces['tertiary']),
            'hover_rgb': rgb_to_hex_raw(surfaces['tertiary']),
            'focus': rgb_to_hex(texts['secondary']),
            'focus_rgb': rgb_to_hex_raw(texts['secondary']),
        },
        'accent': {
            'primary': rgb_to_hex(accents[0]),
            'primary_rgb': rgb_to_hex_raw(accents[0]),
            'secondary': rgb_to_hex(accents[1]),
            'secondary_rgb': rgb_to_hex_raw(accents[1]),
            'tertiary': rgb_to_hex(accents[2]),
            'tertiary_rgb': rgb_to_hex_raw(accents[2]),
            'quaternary': rgb_to_hex(accents[3]),
            'quaternary_rgb': rgb_to_hex_raw(accents[3]),
        },
        'border': {
            'primary': rgb_to_hex(accents[1]),
            'primary_rgb': rgb_to_hex_raw(accents[1]),
            'subtle': rgb_to_hex(surfaces['tertiary']),
            'subtle_rgb': rgb_to_hex_raw(surfaces['tertiary']),
            'accent': rgb_to_hex(texts['primary']),
            'accent_rgb': rgb_to_hex_raw(texts['primary']),
        },
        'terminal': {k: rgb_to_hex(v) for k, v in terminal.items()},
        'oomox': generate_oomox_colors(surfaces, texts, accents, image_name),
        'rgb': {
            'background': list(surfaces['primary']),
            'foreground': list(texts['primary']),
            'accent_primary': list(accents[0]),
            'accent_secondary': list(accents[1]),
            'accent_tertiary': list(accents[2]),
            'accent_quaternary': list(texts['primary']),
            'active': list(accents[0]),
            'hover': list(surfaces['tertiary']),
            'frame': list(surfaces['secondary']),
            'urgent': list(accents[2]),
        },
    }

    return colors


# =============================================================================
# Main Entry Point
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Extract colors from wallpaper and generate theme colors.yaml',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s wallpaper.jpg my-theme
  %(prog)s ~/Pictures/photo.png sunset-theme --output-dir ~/themes
        '''
    )
    parser.add_argument('image', help='Path to wallpaper image')
    parser.add_argument('theme_name', help='Name for the theme')
    parser.add_argument('--output-dir', default='~/.config/themes',
                        help='Output directory (default: ~/.config/themes)')
    parser.add_argument('--num-colors', type=int, default=5,
                        help='Number of accent colors to extract (default: 5)')
    parser.add_argument('--mode', choices=['dark', 'light', 'auto'], default='auto',
                        help='Theme mode (default: auto-detect)')
    parser.add_argument('--quiet', '-q', action='store_true',
                        help='Suppress output')
    args = parser.parse_args()

    # Resolve paths
    image_path = Path(args.image).expanduser().resolve()
    if not image_path.exists():
        print(f"Error: Image not found: {image_path}", file=sys.stderr)
        sys.exit(1)

    output_dir = Path(args.output_dir).expanduser() / args.theme_name
    output_dir.mkdir(parents=True, exist_ok=True)

    if not args.quiet:
        print(f"Extracting colors from {image_path.name}...")

    # Extract accent colors
    accents = extract_colors(image_path, num_colors=args.num_colors)

    if not args.quiet:
        print(f"Found {len(accents)} accent colors")

    # Determine mode
    mode = args.mode
    if mode == 'auto':
        mode = determine_theme_mode(accents)
        if not args.quiet:
            print(f"Detected mode: {mode}")

    # Generate color scheme
    surfaces = generate_surfaces(accents[0], mode)
    texts = generate_text_colors(surfaces['primary'], mode)

    # Ensure accent colors have good contrast against background (WCAG 4.5:1)
    surface_primary = surfaces['primary']
    corrected_accents = []
    for i, accent in enumerate(accents):
        corrected = ensure_contrast(accent, surface_primary, min_ratio=4.5)
        if corrected != accent and not args.quiet:
            print(f"Adjusted accent[{i}] for contrast: {rgb_to_hex(accent)} -> {rgb_to_hex(corrected)}")
        corrected_accents.append(corrected)
    accents = corrected_accents

    terminal = generate_terminal_colors(accents, surfaces, texts, mode)

    # Build complete colors.yaml
    colors = build_colors_yaml(
        args.theme_name, image_path, accents, surfaces, texts, terminal, mode
    )

    # Write colors.yaml
    colors_file = output_dir / 'colors.yaml'
    with open(colors_file, 'w') as f:
        yaml.dump(colors, f, default_flow_style=False, sort_keys=False, allow_unicode=True)

    # Create wallpaper symlink
    wallpaper_ext = image_path.suffix.lower()
    if wallpaper_ext in ['.jpg', '.jpeg']:
        wallpaper_link = output_dir / 'wallpaper.jpg'
    elif wallpaper_ext == '.png':
        wallpaper_link = output_dir / 'wallpaper.png'
    else:
        wallpaper_link = output_dir / f'wallpaper{wallpaper_ext}'

    if wallpaper_link.exists() or wallpaper_link.is_symlink():
        wallpaper_link.unlink()
    wallpaper_link.symlink_to(image_path)

    if not args.quiet:
        print(f"Theme '{args.theme_name}' created at {output_dir}")
        print(f"\nNext: process-templates.sh {args.theme_name}")


if __name__ == '__main__':
    main()
