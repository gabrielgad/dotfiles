# Nushell Environment Configuration
# Environment variables and PATH configuration

# XDG Base Directory Specification
$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
$env.XDG_DATA_HOME = ($env.HOME | path join ".local" "share")
$env.XDG_CACHE_HOME = ($env.HOME | path join ".cache")
$env.XDG_STATE_HOME = ($env.HOME | path join ".local" "state")

# Editor configuration
$env.EDITOR = "nvim"
$env.VISUAL = $env.EDITOR
$env.PAGER = "less"

# Development environment
$env.CARGO_HOME = ($env.HOME | path join ".cargo")
$env.RUSTUP_HOME = ($env.HOME | path join ".rustup")
$env.GOPATH = ($env.HOME | path join ".go")
$env.NODE_OPTIONS = "--max-old-space-size=8192"

# Terminal and shell configuration
$env.TERM = "xterm-kitty"
$env.COLORTERM = "truecolor"
$env.SHELL = "/home/gabe/.cargo/bin/nu"

# Less configuration for better output
$env.LESS = "-R --mouse --wheel-lines=3"
$env.LESSHISTFILE = ($env.XDG_STATE_HOME | path join "less" "history")

# History configuration
$env.HISTFILE = ($env.XDG_STATE_HOME | path join "nushell" "history")
$env.HISTSIZE = 100000
$env.SAVEHIST = 100000

# Language and locale
$env.LANG = "en_US.UTF-8"
$env.LC_ALL = "en_US.UTF-8"

# GPG TTY for signing
$env.GPG_TTY = (tty)

# Starship prompt (if installed)
$env.STARSHIP_SHELL = "nu"
$env.STARSHIP_SESSION_KEY = (random chars --length 16)
$env.STARSHIP_CONFIG = ($env.HOME | path join ".config" "starship.toml")

# Build PATH
$env.PATH = (
    $env.PATH
    | split row (char esep)
    | prepend $"($env.HOME)/.local/bin"
    | prepend $"($env.CARGO_HOME)/bin"
    | prepend $"($env.HOME)/.npm-global/bin" 
    | prepend $"($env.GOPATH)/bin"
    | append "/usr/local/bin"
    | append "/opt/homebrew/bin"  # For macOS compatibility
    | uniq
)

# FZF configuration for better fuzzy finding
$env.FZF_DEFAULT_OPTS = "--height=50% --layout=reverse --border --margin=1 --padding=1"
$env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git"
$env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND
$env.FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git"

# Zellij configuration (disabled for WezTerm compatibility)
# $env.ZELLIJ_AUTO_ATTACH = "true"
# $env.ZELLIJ_AUTO_EXIT = "true"

# BAT (better cat) configuration
$env.BAT_THEME = "TwoDark"
$env.BAT_STYLE = "numbers,changes,header,grid"
$env.BAT_PAGER = "less -RF"

# EZA (better ls) configuration
$env.EZA_COLORS = "ur=0:uw=0:ux=0:ue=0:gr=0:gw=0:gx=0:tr=0:tw=0:tx=0:su=0:sf=0:xa=0"
$env.EZA_ICON_SPACING = "2"

# Git configuration
$env.GIT_PAGER = "delta"

# Development tool configurations
$env.DOCKER_BUILDKIT = "1"
$env.COMPOSE_DOCKER_CLI_BUILD = "1"

# Python configuration
$env.PYTHONDONTWRITEBYTECODE = "1"
$env.PYTHON_HISTORY = ($env.XDG_STATE_HOME | path join "python" "history")

# Node.js configuration
$env.NPM_CONFIG_USERCONFIG = ($env.XDG_CONFIG_HOME | path join "npm" "npmrc")
$env.NPM_CONFIG_CACHE = ($env.XDG_CACHE_HOME | path join "npm")
$env.NPM_CONFIG_PREFIX = ($env.HOME | path join ".npm-global")
$env.NODE_REPL_HISTORY = ($env.XDG_STATE_HOME | path join "node" "repl_history")

# Rust configuration
$env.CARGO_TARGET_DIR = ($env.XDG_CACHE_HOME | path join "cargo" "target")

# Java configuration (if needed)
$env.JAVA_HOME = "/usr/lib/jvm/default"
$env._JAVA_OPTIONS = $"-Djava.util.prefs.userRoot=($env.XDG_CONFIG_HOME)/java"

# Ripgrep configuration
$env.RIPGREP_CONFIG_PATH = ($env.XDG_CONFIG_HOME | path join "ripgrep" "config")

# Create necessary directories
mkdir ($env.XDG_STATE_HOME | path join "nushell")
mkdir ($env.XDG_STATE_HOME | path join "less")
mkdir ($env.XDG_STATE_HOME | path join "python")
mkdir ($env.XDG_STATE_HOME | path join "node")
mkdir ($env.XDG_CONFIG_HOME | path join "npm")
mkdir ($env.XDG_CACHE_HOME | path join "npm")
mkdir ($env.XDG_CACHE_HOME | path join "cargo")
mkdir ($env.XDG_CONFIG_HOME | path join "java")
mkdir ($env.XDG_CONFIG_HOME | path join "ripgrep")

# Set hostname if not already set
if ($env.HOSTNAME? | is-empty) {
    $env.HOSTNAME = (hostname | str trim)
}

# Performance optimizations
$env.NU_USE_IR = "1"  # Enable intermediate representation for better performance

# Zoxide integration
source-env ~/.config/nushell/zoxide.nu

# Starship integration enabled in config.nu
# Environment variables for Starship are set here
# Prompt commands are defined in config.nu