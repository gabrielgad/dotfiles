#!/bin/bash

# LSP Installation Script for Neovim
# Installs language servers for: Go, Rust, Zig, C/C++, TypeScript, F#, C#

set -e

echo "🚀 Installing Language Servers for Neovim..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS and package manager
detect_os_and_package_manager() {
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_FAMILY=$ID_LIKE
    else
        print_error "Cannot detect OS"
        exit 1
    fi
    
    print_status "Detected OS: $OS"
    
    # Find best available package manager (preferred order)
    if command_exists pacman; then
        PKG_MANAGER="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm --needed"
        PKG_UPDATE="sudo pacman -Sy"
    elif command_exists apt; then
        PKG_MANAGER="apt"
        PKG_INSTALL="sudo apt install -y"
        PKG_UPDATE="sudo apt update"
    elif command_exists yay; then
        PKG_MANAGER="yay"
        PKG_INSTALL="yay -S --noconfirm --needed"
        PKG_UPDATE="yay -Sy"
    else
        print_error "No supported package manager found (pacman, apt, yay)"
        exit 1
    fi
    
    print_success "Using package manager: $PKG_MANAGER"
}

# Install package using detected package manager
install_package() {
    local package="$1"
    local arch_package="$2"
    local debian_package="$3"
    
    case "$PKG_MANAGER" in
        "pacman"|"yay")
            $PKG_INSTALL ${arch_package:-$package}
            ;;
        "apt")
            $PKG_INSTALL ${debian_package:-$package}
            ;;
    esac
}

# Install Go LSP (gopls)
install_go_lsp() {
    print_status "Installing Go LSP (gopls)..."
    
    if command_exists go; then
        go install golang.org/x/tools/gopls@latest
        print_success "gopls installed successfully"
    else
        print_warning "Go not found. Installing Go first..."
        install_package "go" "go" "golang-go"
        go install golang.org/x/tools/gopls@latest
        print_success "Go and gopls installed successfully"
    fi
}

# Install Rust LSP (rust-analyzer)
install_rust_lsp() {
    print_status "Installing Rust LSP (rust-analyzer)..."
    
    case "$PKG_MANAGER" in
        "pacman"|"yay")
            install_package "rust-analyzer" "rust-analyzer" ""
            print_success "rust-analyzer installed successfully"
            ;;
        "apt")
            # On Ubuntu/Debian, rust-analyzer might not be in repos
            if command_exists rustup; then
                rustup component add rust-analyzer
                print_success "rust-analyzer installed via rustup"
            else
                print_warning "Installing rust via apt, then rust-analyzer via rustup..."
                install_package "rust" "" "rustc cargo"
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                source ~/.cargo/env
                rustup component add rust-analyzer
                print_success "rust-analyzer installed via rustup"
            fi
            ;;
    esac
}

# Install Zig LSP (zls)
install_zig_lsp() {
    print_status "Installing Zig LSP (zls)..."
    
    # First ensure Zig is installed
    if ! command_exists zig; then
        print_status "Installing Zig first..."
        install_package "zig" "zig" "zig"
    fi
    
    # Try to install zls via package manager
    case "$PKG_MANAGER" in
        "pacman"|"yay")
            if install_package "zls" "zls" "" 2>/dev/null; then
                print_success "zls installed via package manager"
                return 0
            else
                print_warning "Package manager installation failed, trying alternative method..."
            fi
            ;;
        "apt")
            # zls likely not available in Ubuntu repos
            print_status "zls not available in apt, building from source..."
            ;;
    esac
    
    # Fallback: install from GitHub releases
    print_status "Installing zls from GitHub releases..."
    if command_exists zig; then
        temp_dir=$(mktemp -d)
        
        # Try to download prebuilt binary first
        print_status "Downloading prebuilt zls binary..."
        if curl -L https://github.com/zigtools/zls/releases/latest/download/zls-x86_64-linux.tar.xz -o "$temp_dir/zls.tar.xz" 2>/dev/null; then
            cd "$temp_dir"
            tar -xf zls.tar.xz
            if [ -f zls ]; then
                sudo cp zls /usr/local/bin/
                sudo chmod +x /usr/local/bin/zls
                cd - && rm -rf "$temp_dir"
                print_success "zls installed from prebuilt binary"
                return 0
            fi
        fi
        
        # If prebuilt fails, build from source
        print_warning "Prebuilt binary not available, building from source..."
        cd "$temp_dir"
        if git clone https://github.com/zigtools/zls.git 2>/dev/null; then
            cd zls
            if zig build -Doptimize=ReleaseSafe 2>/dev/null; then
                sudo cp zig-out/bin/zls /usr/local/bin/
                sudo chmod +x /usr/local/bin/zls
                cd - && rm -rf "$temp_dir"
                print_success "zls built and installed successfully"
            else
                rm -rf "$temp_dir"
                print_error "Failed to build zls from source"
                return 1
            fi
        else
            rm -rf "$temp_dir"
            print_error "Failed to clone zls repository"
            return 1
        fi
    else
        print_error "Zig not found. Cannot install zls."
        return 1
    fi
}

# Install C/C++ LSP (clangd)
install_clangd() {
    print_status "Installing C/C++ LSP (clangd)..."
    
    install_package "clang" "clang" "clang"
    print_success "clangd installed successfully"
}

# Install TypeScript LSP
install_typescript_lsp() {
    print_status "Installing TypeScript LSP..."
    
    if command_exists npm; then
        npm install -g typescript-language-server typescript
        print_success "typescript-language-server installed successfully"
    else
        print_error "npm not found. Please install Node.js and npm first"
        return 1
    fi
}

# Install F# LSP (FsAutoComplete)
install_fsharp_lsp() {
    print_status "Installing F# LSP (FsAutoComplete)..."
    
    if command_exists dotnet; then
        dotnet tool install --global fsautocomplete
        print_success "FsAutoComplete installed successfully"
    else
        print_warning ".NET not found. Installing .NET first..."
        case "$PKG_MANAGER" in
            "pacman"|"yay")
                install_package "dotnet-runtime dotnet-sdk" "dotnet-runtime dotnet-sdk" ""
                ;;
            "apt")
                # Add Microsoft repo for Ubuntu
                wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
                sudo dpkg -i /tmp/packages-microsoft-prod.deb
                $PKG_UPDATE
                install_package "dotnet-sdk-8.0" "" "dotnet-sdk-8.0"
                ;;
        esac
        dotnet tool install --global fsautocomplete
        print_success ".NET and FsAutoComplete installed successfully"
    fi
}

# Install C# LSP (OmniSharp)
install_csharp_lsp() {
    print_status "Installing C# LSP (OmniSharp)..."
    
    if command_exists dotnet; then
        # Install OmniSharp
        temp_dir=$(mktemp -d)
        
        print_status "Downloading OmniSharp..."
        curl -L https://github.com/OmniSharp/omnisharp-roslyn/releases/latest/download/omnisharp-linux-x64.tar.gz -o "$temp_dir/omnisharp.tar.gz"
        
        print_status "Extracting OmniSharp..."
        tar -xzf "$temp_dir/omnisharp.tar.gz" -C "$temp_dir"
        
        print_status "Installing OmniSharp to /usr/local/omnisharp..."
        sudo mkdir -p /usr/local/omnisharp
        sudo cp -r "$temp_dir"/* /usr/local/omnisharp/
        sudo chmod +x /usr/local/omnisharp/OmniSharp
        sudo ln -sf /usr/local/omnisharp/OmniSharp /usr/local/bin/omnisharp
        
        rm -rf "$temp_dir"
        print_success "OmniSharp installed successfully"
    else
        print_error ".NET not found. Please install .NET first"
        return 1
    fi
}

# Check sudo access
check_sudo() {
    print_status "Checking sudo access (required for some installations)..."
    
    if ! sudo -n true 2>/dev/null; then
        print_status "This script requires sudo access for some installations."
        print_status "You may be prompted for your password."
        sudo -v || {
            print_error "Failed to obtain sudo access. Exiting."
            exit 1
        }
    fi
    
    # Keep sudo alive
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

# Main installation process
main() {
    print_status "Starting LSP installation process..."
    
    # Detect OS and package manager
    detect_os_and_package_manager
    
    # Check sudo access first
    check_sudo
    
    # Update package databases
    print_status "Updating package database..."
    $PKG_UPDATE
    
    # Install each LSP (continue even if some fail)
    install_go_lsp || print_warning "Go LSP installation had issues"
    install_rust_lsp || print_warning "Rust LSP installation had issues"  
    install_zig_lsp || print_warning "Zig LSP installation had issues"
    install_clangd || print_warning "Clang LSP installation had issues"
    install_typescript_lsp || print_warning "TypeScript LSP installation had issues"
    install_fsharp_lsp || print_warning "F# LSP installation had issues"
    install_csharp_lsp || print_warning "C# LSP installation had issues"
    
    echo
    echo "=================================================="
    print_status "🔍 INSTALLATION VERIFICATION"
    echo "=================================================="
    echo
    
    local failed_lsps=()
    local successful_lsps=()
    local failed_languages=()
    local successful_languages=()
    
    # Check LSPs
    if command_exists gopls; then
        successful_lsps+=("gopls")
    else
        failed_lsps+=("gopls")
    fi
    
    if command_exists rust-analyzer; then
        successful_lsps+=("rust-analyzer")
    else
        failed_lsps+=("rust-analyzer")
    fi
    
    if command_exists clangd; then
        successful_lsps+=("clangd")
    else
        failed_lsps+=("clangd")
    fi
    
    if command_exists zls; then
        successful_lsps+=("zls")
    else
        failed_lsps+=("zls")
    fi
    
    if command_exists typescript-language-server; then
        successful_lsps+=("typescript-language-server")
    else
        failed_lsps+=("typescript-language-server")
    fi
    
    if command_exists fsautocomplete; then
        successful_lsps+=("fsautocomplete")
    else
        failed_lsps+=("fsautocomplete")
    fi
    
    if command_exists omnisharp; then
        successful_lsps+=("omnisharp")
    else
        failed_lsps+=("omnisharp")
    fi
    
    # Check Languages
    if command_exists go; then
        successful_languages+=("Go")
    else
        failed_languages+=("Go")
    fi
    
    if command_exists rustc; then
        successful_languages+=("Rust")
    else
        failed_languages+=("Rust")
    fi
    
    if command_exists zig; then
        successful_languages+=("Zig")
    else
        failed_languages+=("Zig")
    fi
    
    if command_exists clang; then
        successful_languages+=("Clang")
    else
        failed_languages+=("Clang")
    fi
    
    if command_exists node; then
        successful_languages+=("Node.js")
    else
        failed_languages+=("Node.js")
    fi
    
    if command_exists dotnet; then
        successful_languages+=(".NET")
    else
        failed_languages+=(".NET")
    fi
    
    # Print LSP results
    if [ ${#successful_lsps[@]} -gt 0 ]; then
        print_success "Successfully installed LSPs:"
        for lsp in "${successful_lsps[@]}"; do
            echo "  ✅ $lsp"
        done
        echo
    fi
    
    if [ ${#failed_lsps[@]} -gt 0 ]; then
        print_error "Failed to install LSPs:"
        for lsp in "${failed_lsps[@]}"; do
            echo "  ❌ $lsp"
        done
        echo
    fi
    
    # Print Language results
    if [ ${#successful_languages[@]} -gt 0 ]; then
        print_success "Successfully installed Languages:"
        for lang in "${successful_languages[@]}"; do
            echo "  ✅ $lang"
        done
        echo
    fi
    
    if [ ${#failed_languages[@]} -gt 0 ]; then
        print_error "Failed to install Languages:"
        for lang in "${failed_languages[@]}"; do
            echo "  ❌ $lang"
        done
        echo
    fi
    
    # Overall status
    local total_failed=$((${#failed_lsps[@]} + ${#failed_languages[@]}))
    
    if [ $total_failed -eq 0 ]; then
        print_success "✨ Installation completed successfully!"
        print_status "All LSPs and languages are ready to use!"
    else
        print_warning "⚠️  Installation partially completed"
        print_status "Some packages failed to install - check error messages above"
    fi
    
    echo
    print_status "🚀 LSP Configuration:"
    print_status "Your init.lua already includes: require('lsp').setup()"
    echo
    print_status "📝 Next steps:"
    print_status "1. Restart your shell: source ~/.config/fish/config.fish"
    print_status "2. Restart Neovim"
    print_status "3. Open a file in any supported language to test LSP functionality"
    echo
    print_status "🔧 Supported languages: Go, Rust, Zig, C/C++, TypeScript, F#, C#"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root. Some installations might not work correctly."
fi

# Run main function
main "$@"