#!/bin/bash

# Project Man Quick Install Script
# Install Project Man CLI tool with one command
# Usage: curl -fsSL https://raw.githubusercontent.com/lockelee/project-man/main/scripts/quick-install.sh | bash

set -e

# Configuration
REPO="lockelee1015/project-man"
VERSION="latest"  # Will be updated by GitHub Actions
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/project-man"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

# Detect platform
detect_platform() {
    local os=$(uname -s)
    local arch=$(uname -m)
    
    case "$os" in
        Linux)
            case "$arch" in
                x86_64) echo "x86_64-unknown-linux-gnu" ;;
                aarch64|arm64) echo "aarch64-unknown-linux-gnu" ;;
                *) log_error "Unsupported architecture: $arch"; exit 1 ;;
            esac
            ;;
        Darwin)
            case "$arch" in
                x86_64) echo "x86_64-apple-darwin" ;;
                arm64) echo "aarch64-apple-darwin" ;;
                *) log_error "Unsupported architecture: $arch"; exit 1 ;;
            esac
            ;;
        *)
            log_error "Unsupported operating system: $os"
            log_error "Supported platforms: Linux (x86_64, ARM64), macOS (Intel, Apple Silicon)"
            exit 1
            ;;
    esac
}

# Get latest release version
get_latest_version() {
    if [ "$VERSION" != "latest" ]; then
        echo "$VERSION"
        return
    fi
    
    log_info "Fetching latest release information..." >&2
    local latest_release
    if command -v curl >/dev/null 2>&1; then
        latest_release=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    elif command -v wget >/dev/null 2>&1; then
        latest_release=$(wget -qO- "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        log_error "curl or wget is required to download Project Man"
        exit 1
    fi
    
    if [ -z "$latest_release" ]; then
        log_error "Failed to get latest release version"
        exit 1
    fi
    
    echo "$latest_release"
}

# Download and extract release
download_release() {
    local version="$1"
    local platform="$2"
    local temp_dir=$(mktemp -d)
    
    log_info "Downloading Project Man $version for $platform..." >&2
    
    local download_url="https://github.com/$REPO/releases/download/$version/project-man-$platform.tar.gz"
    local archive_name="project-man-$platform.tar.gz"
    
    local archive_path="$temp_dir/$archive_name"
    
    # Download the archive
    if command -v curl >/dev/null 2>&1; then
        curl -fL "$download_url" -o "$archive_path"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$download_url" -O "$archive_path"
    else
        log_error "curl or wget is required to download Project Man"
        exit 1
    fi
    
    if [ ! -f "$archive_path" ]; then
        log_error "Failed to download Project Man release"
        exit 1
    fi
    
    # Extract the archive
    log_info "Extracting archive..." >&2
    tar -xzf "$archive_path" -C "$temp_dir"
    
    echo "$temp_dir"
}

# Install binary
install_binary() {
    local extract_dir="$1"
    local platform="$2"
    
    log_info "Installing Project Man binary..."
    
    # Create install directory
    mkdir -p "$INSTALL_DIR"
    
    # Find and copy binary
    local binary_name="p-bin"
    local binary_path=""
    
    # Look for binary in extract directory and subdirectories
    if [ -f "$extract_dir/$binary_name" ]; then
        binary_path="$extract_dir/$binary_name"
    else
        # Search in subdirectories
        binary_path=$(find "$extract_dir" -name "$binary_name" -type f | head -1)
    fi
    
    if [ -z "$binary_path" ] || [ ! -f "$binary_path" ]; then
        log_error "Binary $binary_name not found in extracted archive"
        log_error "Contents of extract directory:"
        ls -la "$extract_dir" >&2
        exit 1
    fi
    
    cp "$binary_path" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/$binary_name"
    
    # Create symlink for easier access
    ln -sf "$INSTALL_DIR/$binary_name" "$INSTALL_DIR/p"
    
    log_success "Binary installed to $INSTALL_DIR/$binary_name"
}


# Setup shell configuration
setup_shell_config() {
    log_info "Setting up shell configuration..."
    
    local shell_config=""
    local shell_name=""
    
    # Detect shell and config file
    if [ -n "$BASH_VERSION" ]; then
        shell_name="bash"
        if [ -f "$HOME/.bashrc" ]; then
            shell_config="$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            shell_config="$HOME/.bash_profile"
        fi
    elif [ -n "$ZSH_VERSION" ]; then
        shell_name="zsh"
        shell_config="$HOME/.zshrc"
    else
        # Try to detect from $SHELL
        case "$SHELL" in
            */bash)
                shell_name="bash"
                shell_config="$HOME/.bashrc"
                ;;
            */zsh)
                shell_name="zsh"
                shell_config="$HOME/.zshrc"
                ;;
            */fish)
                shell_name="fish"
                setup_fish_shell
                return
                ;;
            *)
                log_warn "Unknown shell: $SHELL"
                setup_generic_shell
                return
                ;;
        esac
    fi
    
    if [ -z "$shell_config" ]; then
        log_warn "Could not detect shell configuration file for $shell_name"
        setup_generic_shell
        return
    fi
    
    # Create the shell function inline instead of sourcing external file
    local function_code='
# Project Man shell function
p() {
    local binary_path="'$INSTALL_DIR'/p-bin"
    local cmd="$1"
    
    if [ ! -f "$binary_path" ]; then
        echo "❌ Error: Project Man binary not found at $binary_path"
        return 1
    fi
    
    # Commands that might change directory
    if [ "$cmd" = "go" ] || [ "$cmd" = "add" ]; then
        # Execute command and capture output
        local output=$("$binary_path" "$@" --output-cd 2>&1)
        local exit_code=$?
        
        # Check if command was successful
        if [ $exit_code -eq 0 ]; then
            # Look for CD_TARGET in output
            local cd_target=$(echo "$output" | grep "^CD_TARGET:" | cut -d: -f2-)
            
            if [ -n "$cd_target" ]; then
                # Change to the target directory
                cd "$cd_target" || {
                    echo "❌ Failed to change directory to: $cd_target"
                    return 1
                }
                echo "📁 Changed to: $(pwd)"
            fi
            
            # Show other output (excluding CD_TARGET line)
            echo "$output" | grep -v "^CD_TARGET:"
        else
            # Show error output
            echo "$output"
            return $exit_code
        fi
    else
        # For other commands, just pass through
        "$binary_path" "$@"
    fi
}'
    
    # Check if already configured
    if grep -q "# Project Man shell function" "$shell_config" 2>/dev/null; then
        log_info "Shell integration already configured in $shell_config"
    else
        # Add function to shell config
        echo "" >> "$shell_config"
        echo "$function_code" >> "$shell_config"
        log_success "Shell integration added to $shell_config"
    fi
    
    # Load the function in current shell
    eval "$function_code"
    log_success "Project Man function loaded in current shell session!"
}

# Setup for fish shell
setup_fish_shell() {
    local fish_config="$HOME/.config/fish/config.fish"
    mkdir -p "$(dirname "$fish_config")"
    
    local fish_function='
# Project Man fish function
function p
    set binary_path "'$INSTALL_DIR'/p-bin"
    set cmd $argv[1]
    
    if not test -f "$binary_path"
        echo "❌ Error: Project Man binary not found at $binary_path"
        return 1
    end
    
    # Commands that might change directory
    if test "$cmd" = "go" -o "$cmd" = "add"
        # Execute command and capture output
        set output ($binary_path $argv --output-cd 2>&1)
        set exit_code $status
        
        if test $exit_code -eq 0
            # Look for CD_TARGET in output
            set cd_target (echo "$output" | grep "^CD_TARGET:" | cut -d: -f2-)
            
            if test -n "$cd_target"
                # Change to the target directory
                cd "$cd_target"
                if test $status -eq 0
                    echo "📁 Changed to: "(pwd)
                else
                    echo "❌ Failed to change directory to: $cd_target"
                    return 1
                end
            end
            
            # Show other output (excluding CD_TARGET line)
            echo "$output" | grep -v "^CD_TARGET:"
        else
            # Show error output
            echo "$output"
            return $exit_code
        end
    else
        # For other commands, just pass through
        $binary_path $argv
    end
end'
    
    if grep -q "# Project Man fish function" "$fish_config" 2>/dev/null; then
        log_info "Fish shell integration already configured"
    else
        echo "" >> "$fish_config"
        echo "$fish_function" >> "$fish_config"
        log_success "Fish shell integration added to $fish_config"
    fi
    
    log_info "Fish shell detected. Please restart your terminal or run:"
    log_info "source $fish_config"
}

# Setup for unknown shells
setup_generic_shell() {
    log_warn "Automatic setup not supported for your shell: $SHELL"
    log_info "Please add the following to your shell configuration:"
    echo ""
    echo "# Project Man shell function"
    echo "p() {"
    echo "    local binary_path=\"$INSTALL_DIR/p-bin\""
    echo "    local cmd=\"\$1\""
    echo "    "
    echo "    if [ ! -f \"\$binary_path\" ]; then"
    echo "        echo \"❌ Error: Project Man binary not found at \$binary_path\""
    echo "        return 1"
    echo "    fi"
    echo "    "
    echo "    if [ \"\$cmd\" = \"go\" ] || [ \"\$cmd\" = \"add\" ]; then"
    echo "        local output=\$(\"\$binary_path\" \"\$@\" --output-cd 2>&1)"
    echo "        local exit_code=\$?"
    echo "        if [ \$exit_code -eq 0 ]; then"
    echo "            local cd_target=\$(echo \"\$output\" | grep \"^CD_TARGET:\" | cut -d: -f2-)"
    echo "            if [ -n \"\$cd_target\" ]; then"
    echo "                cd \"\$cd_target\" && echo \"📁 Changed to: \$(pwd)\""
    echo "            fi"
    echo "            echo \"\$output\" | grep -v \"^CD_TARGET:\""
    echo "        else"
    echo "            echo \"\$output\""
    echo "            return \$exit_code"
    echo "        fi"
    echo "    else"
    echo "        \"\$binary_path\" \"\$@\""
    echo "    fi"
    echo "}"
    echo ""
}

# Update PATH
update_path() {
    log_info "Updating PATH configuration..."
    
    # Check if install directory is already in PATH
    if echo "$PATH" | grep -q "$INSTALL_DIR"; then
        log_info "$INSTALL_DIR is already in PATH"
        return
    fi
    
    # Detect shell config file (same logic as above)
    local shell_config=""
    if [ -n "$BASH_VERSION" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            shell_config="$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            shell_config="$HOME/.bash_profile"
        fi
    elif [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
    else
        case "$SHELL" in
            */bash) shell_config="$HOME/.bashrc" ;;
            */zsh) shell_config="$HOME/.zshrc" ;;
        esac
    fi
    
    if [ -n "$shell_config" ]; then
        # Check if PATH update already exists
        if ! grep -q "$INSTALL_DIR" "$shell_config" 2>/dev/null; then
            echo "" >> "$shell_config"
            echo "# Project Man PATH" >> "$shell_config"
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$shell_config"
            log_success "Added $INSTALL_DIR to PATH in $shell_config"
        fi
    else
        log_warn "Could not detect shell configuration file"
        log_info "Please add $INSTALL_DIR to your PATH manually"
    fi
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check if binary exists and is executable
    local binary_path="$INSTALL_DIR/p-bin"
    if [ ! -x "$binary_path" ]; then
        log_error "Binary not found or not executable at $binary_path"
        return 1
    fi
    
    # Test binary execution
    if "$binary_path" --version >/dev/null 2>&1; then
        log_success "Project Man binary is working correctly"
    else
        log_warn "Binary exists but may not be working correctly"
    fi
    
    # Check if shell function is available (test in current shell)
    if command -v p >/dev/null 2>&1; then
        log_success "Shell function is available in current session"
    else
        log_info "Shell function will be available after restarting terminal"
    fi
    
    return 0
}

# Cleanup function
cleanup() {
    if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
}

# Main installation function
main() {
    echo ""
    log_info "🚀 Installing Project Man CLI tool..."
    echo ""
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Detect platform
    local platform=$(detect_platform)
    log_info "Detected platform: $platform"
    
    # Get version to install
    local version=$(get_latest_version)
    log_info "Installing version: $version"
    
    # Download and extract
    local extract_dir=$(download_release "$version" "$platform")
    temp_dir="$extract_dir"
    
    # Install components
    install_binary "$extract_dir" "$platform"
    
    # Setup shell configuration (includes PATH update)
    update_path
    setup_shell_config
    
    # Verify installation
    if verify_installation; then
        echo ""
        log_success "🎉 Project Man has been successfully installed!"
        echo ""
        log_info "You can start using Project Man right now!"
        log_info "Try these commands:"
        log_info "1. Initialize a workspace: p init ~/workspace"
        log_info "2. Add repositories: p add rust-lang/rust"
        log_info "3. Navigate: p go rust"
        echo ""
        log_info "💡 The 'p' command is now available in your current shell!"
        log_info "💡 For new terminals, the function will be automatically loaded"
        echo ""
        log_info "📚 For more information, visit: https://github.com/$REPO"
        echo ""
    else
        log_error "Installation verification failed"
        exit 1
    fi
}

# Run main function
main "$@"