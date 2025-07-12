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
    if [ ! -f "$SCRIPT_DIR/p-bin" ] || [ ! -f "$SCRIPT_DIR/scripts/p-function.sh" ]; then
        log_error "Required files not found. Ensure you have p-bin and scripts/p-function.sh"
        exit 1
    fi
    
    # Create install directory
    log_info "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # Copy files
    log_info "Copying files..."
    cp "$SCRIPT_DIR/p-bin" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/scripts/p-function.sh" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/p-bin"
    
    # Setup shell integration
    setup_shell_integration
    
    log_success "🎉 Installation complete!"
    echo ""
    log_info "Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    log_info "Then try: p init ~/workspace"
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
            echo "source \"$INSTALL_DIR/p-function.sh\""
            return
            ;;
    esac
    
    # Add shell function source if not already there
    local source_line="source \"$INSTALL_DIR/p-function.sh\""
    if ! grep -q "p-function.sh" "$shell_config" 2>/dev/null; then
        echo "" >> "$shell_config"
        echo "# Project Man shell function" >> "$shell_config"
        echo "$source_line" >> "$shell_config"
        log_success "Added shell function to $shell_config"
    else
        log_info "Shell function already configured in $shell_config"
    fi
}

# Run installation
main "$@"