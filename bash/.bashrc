#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# =============================================================================
# OS Detection
# =============================================================================
case "$(uname -s)" in
    Linux*)                OS="linux";;
    MINGW*|MSYS*|CYGWIN*) OS="windows";;
    Darwin*)               OS="mac";;
    *)                     OS="unknown";;
esac

# =============================================================================
# XDG Base Directory Specification
# =============================================================================
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# =============================================================================
# Editor Configuration
# =============================================================================
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less"

# =============================================================================
# Terminal Configuration
# =============================================================================
if [ "$OS" = "linux" ]; then
    export TERM="xterm-kitty"
fi
export COLORTERM="truecolor"

# =============================================================================
# Less Configuration
# =============================================================================
export LESS="-R --mouse --wheel-lines=3"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# =============================================================================
# History Configuration
# =============================================================================
export HISTFILE="$XDG_STATE_HOME/bash/history"
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# =============================================================================
# Locale
# =============================================================================
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# =============================================================================
# Development Environment
# =============================================================================
export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"
export GOPATH="$HOME/.go"
export NODE_OPTIONS="--max-old-space-size=8192"
export VOLTA_HOME="$HOME/.volta"
if [ "$OS" = "linux" ]; then
    export JAVA_HOME="/usr/lib/jvm/default"
fi

# =============================================================================
# PATH
# =============================================================================
export PATH="$HOME/.local/bin:$PATH"
export PATH="$CARGO_HOME/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$GOPATH/bin:$PATH"
export PATH="$VOLTA_HOME/bin:$PATH"
export PATH="$HOME/.dotnet:$PATH"
export PATH="/usr/local/bin:$PATH"

# =============================================================================
# Colors
# =============================================================================
export LS_COLORS="di=1;34:fi=0:ln=1;36:pi=40;33:so=1;35:do=1;35:bd=40;33;1:cd=40;33;1:or=40;31;1:ex=1;32:ow=34;100:*.tar=1;31:*.tgz=1;31:*.arj=1;31:*.taz=1;31:*.lzh=1;31:*.zip=1;31:*.z=1;31:*.Z=1;31:*.gz=1;31:*.bz2=1;31:*.deb=1;31:*.rpm=1;31:*.jar=1;31:*.jpg=1;35:*.jpeg=1;35:*.gif=1;35:*.bmp=1;35:*.pbm=1;35:*.pgm=1;35:*.ppm=1;35:*.tga=1;35:*.xbm=1;35:*.xpm=1;35:*.tif=1;35:*.tiff=1;35:*.png=1;35:*.mov=1;35:*.mpg=1;35:*.mpeg=1;35:*.avi=1;35:*.fli=1;35:*.gl=1;35:*.dl=1;35:*.xcf=1;35:*.xwd=1;35:*.ogg=1;35:*.mp3=1;35:*.wav=1;35"

# =============================================================================
# FZF Configuration
# =============================================================================
export FZF_DEFAULT_OPTS="--height=50% --layout=reverse --border --margin=1 --padding=1"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"

# =============================================================================
# Tool Configuration
# =============================================================================
export BAT_THEME="TwoDark"
export BAT_STYLE="numbers,changes,header,grid"
export BAT_PAGER="less -RF"
export EZA_COLORS="ur=0:uw=0:ux=0:ue=0:gr=0:gw=0:gx=0:tr=0:tw=0:tx=0:su=0:sf=0:xa=0"
export EZA_ICON_SPACING="2"
export GIT_PAGER="delta"
export DOCKER_BUILDKIT="1"
export COMPOSE_DOCKER_CLI_BUILD="1"
export PYTHONDONTWRITEBYTECODE="1"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# =============================================================================
# Local LLM API
# =============================================================================
export OPENAI_API_BASE="https://llm.gabeforge.com/v1"
export OPENAI_API_KEY="sk-localllm-gabeforge-2025"
export OPENAI_MODEL="Qwen3-Coder-30B-A3B-Instruct-Q8_0.gguf"

# =============================================================================
# GPG
# =============================================================================
export GPG_TTY=$(tty)

# =============================================================================
# Starship Prompt
# =============================================================================
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# =============================================================================
# Aliases - File Operations
# =============================================================================
alias ls='ls --color=auto'
alias la='ls -la'
alias ll='ls -l'
alias lt='ls -lt'
alias lh='ls -lh'
alias l='ls'
alias cls='printf "\033[2J\033[3J\033[H"'

# Use eza if available
if command -v eza &> /dev/null; then
    alias tree='eza --tree'
fi

# =============================================================================
# Aliases - Navigation
# =============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# =============================================================================
# Aliases - Tool Replacements
# =============================================================================
alias grep='rg'
alias find='fd'
if command -v bat &> /dev/null; then
    alias cat='bat'
fi
alias top='btop'
alias lg='lazygit'

# =============================================================================
# Aliases - Git
# =============================================================================
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gs='git status'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gm='git merge'
alias gr='git rebase'
alias glog='git log --oneline --graph --decorate'

# =============================================================================
# Functions
# =============================================================================

# mkdir and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}
alias take='mkcd'

# Simple HTTP server
serve() {
    local port="${1:-8000}"
    python -m http.server "$port"
}

# Weather
weather() {
    if [ -z "$1" ]; then
        curl -s "wttr.in/?format=3"
    else
        curl -s "wttr.in/$1?format=3"
    fi
}

# Yazi wrapper - cd to where you navigated when you quit
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if [ -f "$tmp" ]; then
        local cwd="$(cat "$tmp")"
        if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            cd "$cwd"
        fi
        rm -f "$tmp"
    fi
}

# Nvim wrapper - cd to where you navigated (via leader+cd) when you quit
v() {
    local tmp="$(mktemp -t "nvim-cwd.XXXXXX")"
    NVIM_CWD_FILE="$tmp" neovide "$@"
    if [ -f "$tmp" ]; then
        local cwd="$(cat "$tmp")"
        if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            cd "$cwd"
        fi
        rm -f "$tmp"
    fi
}

# =============================================================================
# Vi Mode
# =============================================================================
set -o vi

# =============================================================================
# Shell Options
# =============================================================================
shopt -s autocd
shopt -s cdspell
shopt -s dirspell
shopt -s globstar

# =============================================================================
# Create necessary directories
# =============================================================================
mkdir -p "$XDG_STATE_HOME/bash"
mkdir -p "$XDG_STATE_HOME/less"

# =============================================================================
# Integrations
# =============================================================================

# Zoxide
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
fi

# Starship prompt (load last)
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# Fastfetch on login (Linux only)
if [ "$OS" = "linux" ] && [[ -z "$TMUX" ]] && command -v fastfetch &>/dev/null; then
    fastfetch
fi

# Claude Code with bypassed permissions
alias yolo="claude --dangerously-skip-permissions"

# Cargo environment
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
