#!/bin/bash

# Project Man Installation Script
# This script installs Project Man from a release archive

set -e  # Exit on any error

# Configuration
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/project-man"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're in the right directory (release archive)
check_directory() {
    if [ ! -f "$SCRIPT_DIR/p-bin" ]; then
        # Try source installation if no binary found
        if [ -f "$SCRIPT_DIR/Cargo.toml" ] && [ -f "$SCRIPT_DIR/src/main.rs" ]; then
            log_info "Binary not found, attempting source installation..."
            install_from_source
            return
        fi
        
        log_error "Project Man binary not found in current directory"
        log_error "Please run this script from the extracted release archive directory"
        exit 1
    fi
    
    if [ ! -d "$SCRIPT_DIR/scripts" ]; then
        log_error "Scripts directory not found"
        log_error "Please run this script from the extracted release archive directory"
        exit 1
    fi
}

# Install from source (fallback)
install_from_source() {
    log_info "Installing from source..."
    
    # Check prerequisites
    if ! command -v cargo &> /dev/null; then
        log_error "Rust/Cargo is not installed"
        log_info "Please install Rust from https://rustup.rs/"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed"
        log_info "Please install Git first"
        exit 1
    fi
    
    # Build the project
    log_info "Building Project Man..."
    if cargo build --release; then
        log_success "Build completed successfully"
    else
        log_error "Build failed"
        exit 1
    fi
    
    # Continue with binary installation
    install_binary
    install_shell_integration
    setup_shell_config
    update_path
    verify_installation
}

# Install binary
install_binary() {
    log_info "Installing Project Man binary..."
    
    # Create install directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy binary
    local binary_name="p-bin"
    cp "$SCRIPT_DIR/$binary_name" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/$binary_name"
    
    # Create symlink for easier access
    ln -sf "$INSTALL_DIR/$binary_name" "$INSTALL_DIR/p"
    
    log_success "Binary installed to $INSTALL_DIR/$binary_name"
}

# Install shell integration
install_shell_integration() {
    log_info "Setting up shell integration..."
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    # Copy shell integration files
    cp -r "$SCRIPT_DIR/scripts" "$CONFIG_DIR/"
    
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

# Main installation function
main() {
    echo ""
    log_info "🚀 Installing Project Man CLI tool..."
    echo ""
    
    # Check directory structure
    check_directory
    
    # Install components
    install_binary
    install_shell_integration
    
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
        log_info "📚 For more information, see the README.md file"
        echo ""
    else
        log_error "Installation verification failed"
        exit 1
    fi
}

# Run main function
main "$@"