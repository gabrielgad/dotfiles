#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Dotfiles Installer — OS-aware, idempotent
# =============================================================================

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# OS detection
case "$(uname -s)" in
    Linux*)                OS="linux";;
    MINGW*|MSYS*|CYGWIN*) OS="windows";;
    Darwin*)               OS="mac";;
    *)                     OS="unknown";;
esac

echo "Detected OS: $OS"
echo "Dotfiles dir: $DOTFILES"
echo ""

# -----------------------------------------------------------------------------
# Helper: create a symlink, backing up any existing file/dir
# -----------------------------------------------------------------------------
link() {
    local src="$1"
    local dst="$2"

    # Already a correct symlink
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "[skip] $dst -> $src"
        return
    fi

    # Back up whatever's there
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        local backup="${dst}.backup.${TIMESTAMP}"
        echo "[backup] $dst -> $backup"
        mv "$dst" "$backup"
    fi

    # Ensure parent dir exists
    mkdir -p "$(dirname "$dst")"

    ln -s "$src" "$dst"
    echo "[link] $dst -> $src"
}

# =============================================================================
# Universal symlinks (all machines)
# =============================================================================

echo "--- Universal ---"
link "$DOTFILES/bash/.bashrc"       "$HOME/.bashrc"
link "$DOTFILES/bash/.bash_profile" "$HOME/.bash_profile"
link "$DOTFILES/bash/.profile"      "$HOME/.profile"
link "$DOTFILES/git/.gitconfig"     "$HOME/.gitconfig"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/yazi"               "$HOME/.config/yazi"

# Nvim: different target on Windows
if [ "$OS" = "windows" ]; then
    NVIM_TARGET="${LOCALAPPDATA:-$HOME/AppData/Local}/nvim"
else
    NVIM_TARGET="$HOME/.config/nvim"
fi
link "$DOTFILES/nvim" "$NVIM_TARGET"

# =============================================================================
# Linux-only symlinks
# =============================================================================

if [ "$OS" = "linux" ]; then
    echo ""
    echo "--- Linux-only ---"
    link "$DOTFILES/kitty"    "$HOME/.config/kitty"
    link "$DOTFILES/hypr"     "$HOME/.config/hypr"
    link "$DOTFILES/nushell"  "$HOME/.config/nushell"
    link "$DOTFILES/themes"   "$HOME/.config/themes"
fi

# =============================================================================
# Nvim plugins (clone if missing)
# =============================================================================

echo ""
echo "--- Nvim plugins ---"

PLUGIN_DIR="$HOME/.local/share/nvim/site/pack/plugins/start"
mkdir -p "$PLUGIN_DIR"

declare -A PLUGINS=(
    [oil.nvim]="https://github.com/stevearc/oil.nvim.git"
    [claudecode.nvim]="https://github.com/coder/claudecode.nvim.git"
    [nvim-web-devicons]="https://github.com/nvim-tree/nvim-web-devicons.git"
    [nvim-treesitter]="https://github.com/nvim-treesitter/nvim-treesitter.git"
)

for name in "${!PLUGINS[@]}"; do
    dest="$PLUGIN_DIR/$name"
    if [ -d "$dest" ]; then
        echo "[skip] $name already installed"
    else
        echo "[clone] $name"
        git clone --depth 1 "${PLUGINS[$name]}" "$dest"
    fi
done

# =============================================================================
# Clean up old packer directory if present
# =============================================================================

PACKER_DIR="$HOME/.local/share/nvim/site/pack/packer"
if [ -d "$PACKER_DIR" ]; then
    echo ""
    echo "[cleanup] Removing old packer directory"
    rm -rf "$PACKER_DIR"
fi

# =============================================================================
# Delete dead tmux config
# =============================================================================

if [ -d "$HOME/.config/tmux" ]; then
    echo "[cleanup] Removing dead ~/.config/tmux/"
    rm -rf "$HOME/.config/tmux"
fi

echo ""
echo "Done! Restart your shell or run: source ~/.bashrc"
