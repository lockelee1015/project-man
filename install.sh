#!/bin/bash

# Project Man Installation Script
# Simple installation from release archive

set -e

# Configuration
INSTALL_DIR="$HOME/.local/bin/project-man"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
    log_info "🚀 Installing Project Man..."
    
    # Check files exist
    if [ ! -f "$SCRIPT_DIR/p-bin" ] || [ ! -f "$SCRIPT_DIR/scripts/p" ]; then
        log_error "Required files not found. Ensure you have p-bin and scripts/p"
        exit 1
    fi
    
    # Create install directory
    log_info "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # Copy files
    log_info "Copying files..."
    cp "$SCRIPT_DIR/p-bin" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/scripts/p" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/p-bin"
    chmod +x "$INSTALL_DIR/p"
    
    # Setup shell integration
    setup_shell_integration
    
    log_success "🎉 Installation complete!"
    echo ""
    log_info "Try it now: p --help"
    log_info "Initialize a workspace: p init ~/workspace"
}

setup_shell_integration() {
    log_info "Setting up shell integration..."
    
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
        log_success "Added to PATH in $shell_config"
        log_info "Restart your terminal or run: source $shell_config"
    else
        log_info "Already configured in $shell_config"
    fi
}

# Run installation
main "$@"