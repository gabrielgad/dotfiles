#!/bin/bash

# LSP and Language Uninstall Script for Testing
# Removes language servers and their language dependencies

set -e

echo "🗑️  Uninstalling LSPs and Language Dependencies for Testing..."

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

# Detect package manager
detect_package_manager() {
    if command_exists pacman; then
        PKG_MANAGER="pacman"
        PKG_REMOVE="sudo pacman -Rns --noconfirm"  # Remove with dependencies
    elif command_exists apt; then
        PKG_MANAGER="apt"
        PKG_REMOVE="sudo apt remove --purge -y"
    elif command_exists yay; then
        PKG_MANAGER="yay"
        PKG_REMOVE="yay -Rns --noconfirm"
    else
        print_error "No supported package manager found"
        exit 1
    fi
    
    print_success "Using package manager: $PKG_MANAGER"
}

# Uninstall Go and gopls
uninstall_go() {
    print_status "Uninstalling Go and gopls..."
    
    # Remove gopls
    if [ -f ~/go/bin/gopls ]; then
        rm ~/go/bin/gopls
        print_success "Removed gopls"
    fi
    
    # Remove Go
    case "$PKG_MANAGER" in
        "pacman"|"yay")
            if pacman -Q go >/dev/null 2>&1; then
                $PKG_REMOVE go
                print_success "Removed Go"
            fi
            ;;
        "apt")
            if dpkg -l | grep -q golang-go; then
                $PKG_REMOVE golang-go
                print_success "Removed Go"
            fi
            ;;
    esac
    
    # Remove Go directory
    if [ -d ~/go ]; then
        rm -rf ~/go
        print_success "Removed ~/go directory"
    fi
}

# Uninstall Rust and rust-analyzer
uninstall_rust() {
    print_status "Uninstalling Rust and rust-analyzer..."
    
    # Remove rust-analyzer (system package)
    case "$PKG_MANAGER" in
        "pacman"|"yay")
            if pacman -Q rust-analyzer >/dev/null 2>&1; then
                $PKG_REMOVE rust-analyzer
                print_success "Removed rust-analyzer"
            fi
            if pacman -Q rust >/dev/null 2>&1; then
                $PKG_REMOVE rust
                print_success "Removed Rust"
            fi
            ;;
        "apt")
            if dpkg -l | grep -q rustc; then
                $PKG_REMOVE rustc cargo
                print_success "Removed Rust"
            fi
            ;;
    esac
    
    # Remove rustup installation
    if [ -d ~/.rustup ]; then
        rm -rf ~/.rustup
        print_success "Removed ~/.rustup"
    fi
    
    if [ -d ~/.cargo ]; then
        rm -rf ~/.cargo
        print_success "Removed ~/.cargo"
    fi
}

# Uninstall Zig and zls
uninstall_zig() {
    print_status "Uninstalling Zig and zls..."
    
    # Remove zls
    if command_exists zls; then
        case "$PKG_MANAGER" in
            "pacman"|"yay")
                if pacman -Q zls >/dev/null 2>&1; then
                    $PKG_REMOVE zls
                    print_success "Removed zls"
                fi
                ;;
        esac
    fi
    
    # Remove manually installed zls
    if [ -f /usr/local/bin/zls ]; then
        sudo rm /usr/local/bin/zls
        print_success "Removed manually installed zls"
    fi
    
    # Remove Zig
    case "$PKG_MANAGER" in
        "pacman"|"yay")
            if pacman -Q zig >/dev/null 2>&1; then
                $PKG_REMOVE zig
                print_success "Removed Zig"
            fi
            ;;
        "apt")
            if dpkg -l | grep -q zig; then
                $PKG_REMOVE zig
                print_success "Removed Zig"
            fi
            ;;
    esac
}

# Uninstall C/C++ tools
uninstall_clang() {
    print_status "Uninstalling clang/clangd..."
    
    case "$PKG_MANAGER" in
        "pacman"|"yay")
            if pacman -Q clang >/dev/null 2>&1; then
                if $PKG_REMOVE clang 2>/dev/null; then
                    print_success "Removed clang"
                else
                    print_warning "Could not remove clang (has system dependencies)"
                    print_status "clangd LSP will still be available from existing clang installation"
                fi
            fi
            ;;
        "apt")
            if dpkg -l | grep -q clang; then
                if $PKG_REMOVE clang 2>/dev/null; then
                    print_success "Removed clang"
                else
                    print_warning "Could not remove clang (has system dependencies)"
                fi
            fi
            ;;
    esac
}

# Uninstall TypeScript LSP and Node.js
uninstall_typescript() {
    print_status "Uninstalling TypeScript LSP and Node.js..."
    
    # Remove npm global packages
    if command_exists npm; then
        if npm list -g typescript-language-server >/dev/null 2>&1; then
            npm uninstall -g typescript-language-server
            print_success "Removed typescript-language-server"
        fi
        
        if npm list -g typescript >/dev/null 2>&1; then
            npm uninstall -g typescript
            print_success "Removed TypeScript"
        fi
    fi
    
    # Remove Node.js (optional - commented out as you might need it for other things)
    # case "$PKG_MANAGER" in
    #     "pacman"|"yay")
    #         if pacman -Q nodejs npm >/dev/null 2>&1; then
    #             $PKG_REMOVE nodejs npm
    #             print_success "Removed Node.js and npm"
    #         fi
    #         ;;
    #     "apt")
    #         if dpkg -l | grep -q nodejs; then
    #             $PKG_REMOVE nodejs npm
    #             print_success "Removed Node.js and npm"
    #         fi
    #         ;;
    # esac
}

# Uninstall .NET and F#/C# LSPs
uninstall_dotnet() {
    print_status "Uninstalling .NET and F#/C# LSPs..."
    
    # Remove dotnet tools
    if command_exists dotnet; then
        if dotnet tool list -g | grep -q fsautocomplete; then
            dotnet tool uninstall --global fsautocomplete
            print_success "Removed FsAutoComplete"
        fi
    fi
    
    # Remove OmniSharp
    if [ -f /usr/local/bin/omnisharp ]; then
        sudo rm -f /usr/local/bin/omnisharp
        sudo rm -rf /usr/local/omnisharp
        print_success "Removed OmniSharp"
    fi
    
    # Remove .NET
    case "$PKG_MANAGER" in
        "pacman"|"yay")
            if pacman -Q dotnet-runtime dotnet-sdk >/dev/null 2>&1; then
                $PKG_REMOVE dotnet-runtime dotnet-sdk
                print_success "Removed .NET"
            fi
            ;;
        "apt")
            if dpkg -l | grep -q dotnet; then
                $PKG_REMOVE dotnet-sdk-8.0 dotnet-runtime-8.0 2>/dev/null || true
                print_success "Removed .NET"
            fi
            # Remove Microsoft repo
            if [ -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
                sudo rm -f /etc/apt/sources.list.d/microsoft-prod.list
                print_success "Removed Microsoft APT repository"
            fi
            ;;
    esac
    
    # Remove .NET directories
    if [ -d ~/.dotnet ]; then
        rm -rf ~/.dotnet
        print_success "Removed ~/.dotnet"
    fi
}

# Manual cleanup for remaining LSPs
manual_cleanup() {
    print_status "Performing manual cleanup of remaining LSPs..."
    
    # Remove typescript-language-server from npm global
    if [ -f ~/.npm-global/bin/typescript-language-server ]; then
        rm -f ~/.npm-global/bin/typescript-language-server
        rm -f ~/.npm-global/bin/tsserver 2>/dev/null || true
        print_success "Manually removed typescript-language-server"
    fi
    
    # Remove system LSPs that might be protected
    if command_exists rust-analyzer; then
        sudo pacman -Rdd rust-analyzer --noconfirm 2>/dev/null || print_warning "Could not remove rust-analyzer"
    fi
    
    if command_exists clangd; then
        sudo pacman -Rdd clang --noconfirm 2>/dev/null || print_warning "Could not remove clang"
    fi
    
    if command_exists zls; then
        sudo pacman -Rdd zls --noconfirm 2>/dev/null || print_warning "Could not remove zls"
    fi
    
    # Force remove npm global directory contents
    if [ -d ~/.npm-global ]; then
        rm -rf ~/.npm-global/lib/node_modules/typescript* 2>/dev/null || true
        rm -rf ~/.npm-global/lib/node_modules/@types* 2>/dev/null || true
        print_success "Cleaned npm global directory"
    fi
}

# Check sudo access
check_sudo() {
    print_status "Checking sudo access (required for package removal)..."
    
    if ! sudo -n true 2>/dev/null; then
        print_status "This script requires sudo access for package removal."
        print_status "You may be prompted for your password."
        sudo -v || {
            print_error "Failed to obtain sudo access. Exiting."
            exit 1
        }
    fi
    
    # Keep sudo alive during the script execution
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

# Main uninstall process
main() {
    print_warning "This will remove ALL LSPs and their language dependencies!"
    print_warning "This is intended for testing the installation script."
    print_warning "This script requires sudo privileges to remove system packages."
    echo
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Uninstall cancelled."
        exit 0
    fi
    
    print_status "Starting LSP and language uninstall process..."
    
    # Check sudo access first
    check_sudo
    
    # Detect package manager
    detect_package_manager
    
    # Uninstall everything
    uninstall_go
    uninstall_rust
    uninstall_zig
    uninstall_clang
    uninstall_typescript
    uninstall_dotnet
    
    # Manual cleanup for stubborn packages
    manual_cleanup
    
    # Final verification
    print_status "Verifying uninstall results..."
    echo
    
    local failed_lsps=()
    local successful_lsps=()
    local failed_languages=()
    local successful_languages=()
    
    # Check LSPs
    if command_exists gopls; then
        failed_lsps+=("gopls")
    else
        successful_lsps+=("gopls")
    fi
    
    if command_exists rust-analyzer; then
        failed_lsps+=("rust-analyzer")
    else
        successful_lsps+=("rust-analyzer")
    fi
    
    if command_exists clangd; then
        failed_lsps+=("clangd (expected - has system dependencies)")
    else
        successful_lsps+=("clangd")
    fi
    
    if command_exists zls; then
        failed_lsps+=("zls")
    else
        successful_lsps+=("zls")
    fi
    
    if command_exists typescript-language-server; then
        failed_lsps+=("typescript-language-server")
    else
        successful_lsps+=("typescript-language-server")
    fi
    
    if command_exists fsautocomplete; then
        failed_lsps+=("fsautocomplete")
    else
        successful_lsps+=("fsautocomplete")
    fi
    
    if command_exists omnisharp; then
        failed_lsps+=("omnisharp")
    else
        successful_lsps+=("omnisharp")
    fi
    
    # Check Languages
    if command_exists go; then
        failed_languages+=("Go")
    else
        successful_languages+=("Go")
    fi
    
    if command_exists rustc; then
        failed_languages+=("Rust")
    else
        successful_languages+=("Rust")
    fi
    
    if command_exists zig; then
        failed_languages+=("Zig")
    else
        successful_languages+=("Zig")
    fi
    
    if command_exists clang; then
        failed_languages+=("Clang (expected - has system dependencies)")
    else
        successful_languages+=("Clang")
    fi
    
    if command_exists node; then
        failed_languages+=("Node.js (intentionally kept)")
    else
        successful_languages+=("Node.js")
    fi
    
    if command_exists dotnet; then
        failed_languages+=(".NET")
    else
        successful_languages+=(".NET")
    fi
    
    # Print LSP results
    if [ ${#successful_lsps[@]} -gt 0 ]; then
        print_success "Successfully removed LSPs:"
        for lsp in "${successful_lsps[@]}"; do
            echo "  ✅ $lsp"
        done
        echo
    fi
    
    if [ ${#failed_lsps[@]} -gt 0 ]; then
        print_warning "LSPs still present:"
        for lsp in "${failed_lsps[@]}"; do
            echo "  ❌ $lsp"
        done
        echo
    fi
    
    # Print Language results
    if [ ${#successful_languages[@]} -gt 0 ]; then
        print_success "Successfully removed Languages:"
        for lang in "${successful_languages[@]}"; do
            echo "  ✅ $lang"
        done
        echo
    fi
    
    if [ ${#failed_languages[@]} -gt 0 ]; then
        print_warning "Languages still present:"
        for lang in "${failed_languages[@]}"; do
            echo "  ❌ $lang"
        done
        echo
    fi
    
    # Overall status
    local total_failed=$((${#failed_lsps[@]} + ${#failed_languages[@]}))
    local expected_failures=0
    
    # Count expected failures (clangd and Node.js)
    for item in "${failed_lsps[@]}" "${failed_languages[@]}"; do
        if [[ "$item" == *"expected"* ]] || [[ "$item" == *"intentionally"* ]]; then
            ((expected_failures++))
        fi
    done
    
    if [ $((total_failed - expected_failures)) -eq 0 ]; then
        print_success "✨ Uninstall completed successfully!"
        print_status "All target packages removed (kept system dependencies)"
    else
        print_warning "⚠️  Uninstall partially completed"
        print_status "Some packages may still be installed"
    fi
    
    echo
    print_status "🚀 You can now test the installation script:"
    print_status "   ~/.config/nvim/install_lsps.sh"
}

# Run main function
main "$@"