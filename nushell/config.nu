# Nushell Configuration
# Enhanced configuration for a beautiful and productive shell experience

# Starship prompt configuration
$env.PROMPT_MULTILINE_INDICATOR = "::: "
$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ": "
$env.PROMPT_INDICATOR_VI_NORMAL = "〉"

def create_left_prompt [] {
    ^starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)' --terminal-width (term size).columns
}

def create_right_prompt [] {
    ^starship prompt --right --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)' --terminal-width (term size).columns
}

$env.PROMPT_COMMAND = {|| create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }

# Color configuration
$env.LS_COLORS = "di=1;34:fi=0:ln=1;36:pi=40;33:so=1;35:do=1;35:bd=40;33;1:cd=40;33;1:or=40;31;1:ex=1;32:ow=34;100:*.tar=1;31:*.tgz=1;31:*.arj=1;31:*.taz=1;31:*.lzh=1;31:*.zip=1;31:*.z=1;31:*.Z=1;31:*.gz=1;31:*.bz2=1;31:*.deb=1;31:*.rpm=1;31:*.jar=1;31:*.jpg=1;35:*.jpeg=1;35:*.gif=1;35:*.bmp=1;35:*.pbm=1;35:*.pgm=1;35:*.ppm=1;35:*.tga=1;35:*.xbm=1;35:*.xpm=1;35:*.tif=1;35:*.tiff=1;35:*.png=1;35:*.mov=1;35:*.mpg=1;35:*.mpeg=1;35:*.avi=1;35:*.fli=1;35:*.gl=1;35:*.dl=1;35:*.xcf=1;35:*.xwd=1;35:*.ogg=1;35:*.mp3=1;35:*.wav=1;35"

# Useful aliases
alias la = ls -la
alias ll = ls -l
alias lt = ls -lt
alias lh = ls -lh
alias l = ls
alias .. = cd ..
alias ... = cd ../..
alias .... = cd ../../..
alias grep = rg
alias find = fd
alias cat = if (which bat | is-empty) { cat } else { bat }
alias top = btop
# Clear screen AND scrollback buffer (true clear)
def cls [] { print -n $"\e[2J\e[3J\e[H" }
alias tree = if (which eza | is-empty) { tree } else { eza --tree }
alias lg = lazygit
# Yazi wrapper function - changes directory to where you navigated when you quit
def --env y [...args] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX")
    ^yazi ...$args --cwd-file $tmp
    if ($tmp | path exists) {
        let cwd = (open $tmp | str trim)
        if ($cwd != "" and $cwd != $env.PWD) {
            cd $cwd
        }
        rm -f $tmp
    }
}

# Git aliases
alias g = git
alias ga = git add
alias gc = git commit
alias gp = git push
alias gl = git pull
alias gs = git status
alias gd = git diff
alias gb = git branch
alias gco = git checkout
alias gm = git merge
alias gr = git rebase
alias glog = git log --oneline --graph --decorate

# Directory navigation helpers
def mkcd [name: string] {
    mkdir $name
    cd $name
}

def take [name: string] {
    mkcd $name
}

# Development helpers
def serve [port: int = 8000] {
    python -m http.server $port
}

def weather [city: string = ""] {
    if ($city | is-empty) {
        curl -s "wttr.in/?format=3"
    } else {
        curl -s $"wttr.in/($city)?format=3"
    }
}

# Enhanced ls with exa if available
def enhanced_ls [...args] {
    if (which eza | is-empty) {
        ls ...$args
    } else {
        eza --color=always --group-directories-first --icons ...$args
    }
}

# System information
def sysinfo [] {
    let os = (sys host | get name)
    let kernel = (sys host | get kernel_version)
    let uptime = (sys host | get uptime)
    let memory = (sys mem)
    let disk = (sys disks | first)
    
    print $"(ansi cyan)System Information(ansi reset)"
    print $"OS: ($os)"
    print $"Kernel: ($kernel)"
    print $"Uptime: ($uptime)"
    print $"Memory: (($memory.used / 1GB) | math round --precision 1)GB / (($memory.total / 1GB) | math round --precision 1)GB"
    print $"Disk: (($disk.free / 1GB) | math round --precision 1)GB free of (($disk.total / 1GB) | math round --precision 1)GB"
}

# Zellij auto-start disabled - using WezTerm multiplexing instead

# Key bindings and editor configuration
$env.config = {
    show_banner: true
    # use_grid_icons: true  # Removed in Nu 0.105.1
    footer_mode: 25
    float_precision: 2
    use_ansi_coloring: true
    edit_mode: vi
    shell_integration: {
        osc2: true
        osc7: true
        osc8: true
        osc9_9: false
        osc133: true
        osc633: true
        reset_application_mode: true
    }
    use_kitty_protocol: true
    highlight_resolved_externals: true
    
    cursor_shape: {
        emacs: line
        vi_insert: line
        vi_normal: block
    }
    
    color_config: {
        separator: white
        leading_trailing_space_bg: { attr: n }
        header: green_bold
        empty: blue
        bool: light_cyan
        int: white
        filesize: cyan
        duration: white
        date: purple
        range: white
        float: white
        string: white
        nothing: white
        binary: white
        cellpath: white
        row_index: green_bold
        record: white
        list: white
        block: white
        hints: dark_gray
        search_result: red_bold
        shape_and: purple_bold
        shape_binary: purple_bold
        shape_block: blue_bold
        shape_bool: light_cyan
        shape_closure: green_bold
        shape_custom: green
        shape_datetime: cyan_bold
        shape_directory: blue
        shape_external: cyan
        shape_externalarg: green_bold
        shape_filepath: cyan
        shape_flag: blue_bold
        shape_float: purple_bold
        shape_garbage: { fg: white bg: red attr: b}
        shape_globpattern: cyan_bold
        shape_int: purple_bold
        shape_internalcall: cyan_bold
        shape_list: cyan_bold
        shape_literal: blue
        shape_match_pattern: green
        shape_matching_brackets: { attr: u }
        shape_nothing: light_cyan
        shape_operator: yellow
        shape_or: purple_bold
        shape_pipe: purple_bold
        shape_range: yellow_bold
        shape_record: cyan_bold
        shape_redirection: purple_bold
        shape_signature: green_bold
        shape_string: green
        shape_string_interpolation: cyan_bold
        shape_table: blue_bold
        shape_variable: purple
        shape_vardecl: purple
    }
    
    # filesize config moved to different location in Nu 0.105.1
    
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
        external: {
            enable: true
            max_results: 100
            completer: null
        }
    }
    
    history: {
        max_size: 100_000
        sync_on_enter: true
        file_format: "sqlite"
        isolation: false
    }
    
    keybindings: [
        {
            name: completion_menu
            modifier: none
            keycode: tab
            mode: [emacs vi_normal vi_insert]
            event: {
                until: [
                    { send: menu name: completion_menu }
                    { send: menunext }
                    { edit: complete }
                ]
            }
        }
        {
            name: history_menu
            modifier: control
            keycode: char_r
            mode: [emacs, vi_insert, vi_normal]
            event: { send: menu name: history_menu }
        }
        {
            name: help_menu
            modifier: none
            keycode: f1
            mode: [emacs, vi_insert, vi_normal]
            event: { send: menu name: help_menu }
        }
    ]
    
    menus: [
        {
            name: completion_menu
            only_buffer_difference: false
            marker: "| "
            type: {
                layout: columnar
                columns: 4
                col_width: 20
                col_padding: 2
            }
            style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
            }
        }
        {
            name: history_menu
            only_buffer_difference: true
            marker: "? "
            type: {
                layout: list
                page_size: 10
            }
            style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
            }
        }
        {
            name: help_menu
            only_buffer_difference: true
            marker: "? "
            type: {
                layout: description
                columns: 4
                col_width: 20
                col_padding: 2
                selection_rows: 4
                description_rows: 10
            }
            style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
            }
        }
    ]
}

# Claude Code with bypassed permissions
alias yolo = ["claude", "--dangerously-skip-permissions"]
source $"($nu.home-path)/.cargo/env.nu"
