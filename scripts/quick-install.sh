#!/bin/bash

# Project Man Quick Install Script
# Install Project Man CLI tool with one command
# Usage: curl -fsSL https://raw.githubusercontent.com/lockelee/project-man/main/scripts/quick-install.sh | bash

set -e

# Configuration
REPO="lockelee/project-man"
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
        MINGW*|MSYS*|CYGWIN*)
            echo "x86_64-pc-windows-msvc"
            ;;
        *)
            log_error "Unsupported operating system: $os"
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
    
    log_info "Fetching latest release information..."
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
    
    log_info "Downloading Project Man $version for $platform..."
    
    local download_url="https://github.com/$REPO/releases/download/$version/project-man-$platform"
    local archive_name
    
    if [[ "$platform" == *"windows"* ]]; then
        archive_name="project-man-$platform.zip"
        download_url="$download_url.zip"
    else
        archive_name="project-man-$platform.tar.gz"
        download_url="$download_url.tar.gz"
    fi
    
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
    log_info "Extracting archive..."
    if [[ "$archive_name" == *.zip ]]; then
        if command -v unzip >/dev/null 2>&1; then
            unzip -q "$archive_path" -d "$temp_dir"
        else
            log_error "unzip is required to extract the downloaded archive"
            exit 1
        fi
    else
        tar -xzf "$archive_path" -C "$temp_dir"
    fi
    
    echo "$temp_dir"
}

# Install binary
install_binary() {
    local extract_dir="$1"
    local platform="$2"
    
    log_info "Installing Project Man binary..."
    
    # Create install directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy binary
    local binary_name="p-bin"
    if [[ "$platform" == *"windows"* ]]; then
        binary_name="p-bin.exe"
    fi
    
    cp "$extract_dir/$binary_name" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/$binary_name"
    
    # Create symlink for easier access (if not Windows)
    if [[ "$platform" != *"windows"* ]]; then
        ln -sf "$INSTALL_DIR/$binary_name" "$INSTALL_DIR/p"
    fi
    
    log_success "Binary installed to $INSTALL_DIR/$binary_name"
}

# Install shell integration
install_shell_integration() {
    local extract_dir="$1"
    
    log_info "Setting up shell integration..."
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    # Copy shell integration files
    cp -r "$extract_dir/scripts" "$CONFIG_DIR/"
    
    # Make scripts executable
    chmod +x "$CONFIG_DIR/scripts/"*.sh
    
    log_success "Shell integration files installed to $CONFIG_DIR/scripts/"
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
                log_warn "Fish shell detected. Manual setup required."
                log_info "Add this to your fish config: source $CONFIG_DIR/scripts/p-function.sh"
                return
                ;;
            *)
                log_warn "Unknown shell. Manual setup required."
                log_info "Add this to your shell config: source $CONFIG_DIR/scripts/p-function.sh"
                return
                ;;
        esac
    fi
    
    if [ -z "$shell_config" ]; then
        log_warn "Could not detect shell configuration file for $shell_name"
        log_info "Please add this line to your shell configuration:"
        log_info "source $CONFIG_DIR/scripts/p-function.sh"
        return
    fi
    
    # Check if already configured
    local source_line="source $CONFIG_DIR/scripts/p-function.sh"
    if grep -q "source.*p-function.sh" "$shell_config" 2>/dev/null; then
        log_info "Shell integration already configured in $shell_config"
        return
    fi
    
    # Add source line to shell config
    echo "" >> "$shell_config"
    echo "# Project Man shell integration" >> "$shell_config"
    echo "$source_line" >> "$shell_config"
    
    log_success "Shell integration added to $shell_config"
    log_info "Please restart your terminal or run: source $shell_config"
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
    
    # Check shell integration files
    if [ -f "$CONFIG_DIR/scripts/p-function.sh" ]; then
        log_success "Shell integration files are installed"
    else
        log_error "Shell integration files are missing"
        return 1
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
    install_shell_integration "$extract_dir"
    
    # Setup shell configuration
    update_path
    setup_shell_config
    
    # Verify installation
    if verify_installation; then
        echo ""
        log_success "🎉 Project Man has been successfully installed!"
        echo ""
        log_info "Next steps:"
        log_info "1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
        log_info "2. Initialize a workspace: p init ~/workspace"
        log_info "3. Add repositories: p add rust-lang/rust"
        log_info "4. Navigate: p go rust"
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