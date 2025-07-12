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
    
    log_info "Installing Project Man binary..." >&2
    
    # Create install directory  
    mkdir -p "$INSTALL_DIR"
    
    # Find binary and wrapper script
    local binary_path=""
    local wrapper_path=""
    
    # Look for binary
    if [ -f "$extract_dir/p-bin" ]; then
        binary_path="$extract_dir/p-bin"
    else
        binary_path=$(find "$extract_dir" -name "p-bin" -type f | head -1)
    fi
    
    # Look for wrapper script
    if [ -f "$extract_dir/scripts/p" ]; then
        wrapper_path="$extract_dir/scripts/p"
    else
        wrapper_path=$(find "$extract_dir" -name "p" -type f | head -1)
    fi
    
    if [ -z "$binary_path" ] || [ ! -f "$binary_path" ]; then
        log_error "Binary p-bin not found in extracted archive"
        log_error "Contents of extract directory:"
        ls -la "$extract_dir" >&2
        exit 1
    fi
    
    if [ -z "$wrapper_path" ] || [ ! -f "$wrapper_path" ]; then
        log_error "Wrapper script p not found in extracted archive"
        log_error "Contents of extract directory:"
        ls -la "$extract_dir" >&2
        exit 1
    fi
    
    # Copy files
    cp "$binary_path" "$INSTALL_DIR/"
    cp "$wrapper_path" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/p-bin"
    chmod +x "$INSTALL_DIR/p"
    
    log_success "Binary and wrapper installed to $INSTALL_DIR/" >&2
}


# Setup shell integration
setup_shell_integration() {
    log_info "Setting up shell integration..." >&2
    
    local shell_config=""
    case "$SHELL" in
        */bash) shell_config="$HOME/.bashrc" ;;
        */zsh) shell_config="$HOME/.zshrc" ;;
        *) 
            log_error "Unsupported shell: $SHELL"
            log_info "Please add this line to your shell config manually:"
            echo "export PATH=\"$INSTALL_DIR:\$PATH\""
            return
            ;;
    esac
    
    # Add to PATH if not already there
    if ! grep -q "$INSTALL_DIR" "$shell_config" 2>/dev/null; then
        echo "" >> "$shell_config"
        echo "# Project Man" >> "$shell_config"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$shell_config"
        log_success "Added to PATH in $shell_config" >&2
        log_info "Restart your terminal or run: source $shell_config" >&2
    else
        log_info "Already configured in $shell_config" >&2
    fi
}


# Verify installation
verify_installation() {
    log_info "Verifying installation..." >&2
    
    # Check if binary and wrapper exist and are executable
    if [ ! -x "$INSTALL_DIR/p-bin" ]; then
        log_error "Binary not found or not executable at $INSTALL_DIR/p-bin"
        return 1
    fi
    
    if [ ! -x "$INSTALL_DIR/p" ]; then
        log_error "Wrapper script not found or not executable at $INSTALL_DIR/p"
        return 1
    fi
    
    # Test binary execution
    if "$INSTALL_DIR/p-bin" --version >/dev/null 2>&1; then
        log_success "Project Man binary is working correctly" >&2
    else
        log_warn "Binary exists but may not be working correctly" >&2
    fi
    
    log_success "Installation verified successfully" >&2
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
    
    # Install binary to consistent location
    install_binary "$extract_dir"
    
    # Setup shell integration (add to PATH)
    setup_shell_integration
    
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
        log_info "💡 The 'p' command will be available after restarting your terminal"
        log_info "💡 Both 'p go' and 'p add' will automatically change directories"
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