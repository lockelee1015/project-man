#!/bin/bash

# Project Man Installation Script
# This script builds and installs Project Man from source

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "Cargo.toml" ] || [ ! -f "src/main.rs" ]; then
    print_error "This script must be run from the project-man directory"
    print_info "Please cd to the project-man directory and run this script again"
    exit 1
fi

print_info "Starting Project Man installation..."
echo

# Check prerequisites
print_info "Checking prerequisites..."

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    print_error "Rust/Cargo is not installed"
    print_info "Please install Rust from https://rustup.rs/"
    exit 1
fi
print_success "Rust/Cargo found"

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed"
    print_info "Please install Git first"
    exit 1
fi
print_success "Git found"

echo

# Build the project
print_info "Building Project Man..."
if cargo build --release; then
    print_success "Build completed successfully"
else
    print_error "Build failed"
    exit 1
fi

echo

# Determine installation method
print_info "Choose installation method:"
echo "1) System-wide installation (requires sudo, installs to /usr/local/bin)"
echo "2) User installation (installs to ~/.local/bin)"
echo "3) Add to PATH only (keeps files in current directory)"
echo "4) Shell function only (no binary installation)"

while true; do
    read -p "Enter your choice (1-4): " choice
    case $choice in
        [1]* ) 
            install_method="system"
            break
            ;;
        [2]* ) 
            install_method="user"
            break
            ;;
        [3]* ) 
            install_method="path"
            break
            ;;
        [4]* ) 
            install_method="function"
            break
            ;;
        * ) 
            echo "Please enter 1, 2, 3, or 4"
            ;;
    esac
done

echo

# Install based on chosen method
case $install_method in
    "system")
        print_info "Installing system-wide..."
        
        # Copy binary
        if sudo cp target/release/p-bin /usr/local/bin/; then
            print_success "Binary installed to /usr/local/bin/p-bin"
        else
            print_error "Failed to install binary"
            exit 1
        fi
        
        # Make sure it's executable
        sudo chmod +x /usr/local/bin/p-bin
        
        # Create shell function file
        sudo tee /usr/local/bin/p-function.sh > /dev/null << 'EOF'
#!/bin/bash
p() {
    local binary_path="/usr/local/bin/p-bin"
    local cmd="$1"
    
    if [ "$cmd" = "go" ] || [ "$cmd" = "add" ]; then
        local output=$("$binary_path" "$@" --output-cd 2>&1)
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            local cd_target=$(echo "$output" | grep "^CD_TARGET:" | cut -d: -f2-)
            
            if [ -n "$cd_target" ]; then
                cd "$cd_target" || {
                    echo "❌ Failed to change directory to: $cd_target"
                    return 1
                }
                echo "📁 Changed to: $(pwd)"
            fi
            
            echo "$output" | grep -v "^CD_TARGET:"
        else
            echo "$output"
            return $exit_code
        fi
    else
        "$binary_path" "$@"
    fi
}
EOF
        
        sudo chmod +x /usr/local/bin/p-function.sh
        print_success "Shell function installed to /usr/local/bin/p-function.sh"
        
        # Add to shell configs
        shell_config_line="source /usr/local/bin/p-function.sh"
        ;;
        
    "user")
        print_info "Installing for current user..."
        
        # Create ~/.local/bin if it doesn't exist
        mkdir -p ~/.local/bin
        
        # Copy binary
        cp target/release/p-bin ~/.local/bin/
        chmod +x ~/.local/bin/p-bin
        print_success "Binary installed to ~/.local/bin/p-bin"
        
        # Create shell function file
        cat > ~/.local/bin/p-function.sh << 'EOF'
#!/bin/bash
p() {
    local binary_path="$HOME/.local/bin/p-bin"
    local cmd="$1"
    
    if [ "$cmd" = "go" ] || [ "$cmd" = "add" ]; then
        local output=$("$binary_path" "$@" --output-cd 2>&1)
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            local cd_target=$(echo "$output" | grep "^CD_TARGET:" | cut -d: -f2-)
            
            if [ -n "$cd_target" ]; then
                cd "$cd_target" || {
                    echo "❌ Failed to change directory to: $cd_target"
                    return 1
                }
                echo "📁 Changed to: $(pwd)"
            fi
            
            echo "$output" | grep -v "^CD_TARGET:"
        else
            echo "$output"
            return $exit_code
        fi
    else
        "$binary_path" "$@"
    fi
}
EOF
        
        chmod +x ~/.local/bin/p-function.sh
        print_success "Shell function installed to ~/.local/bin/p-function.sh"
        
        shell_config_line="source ~/.local/bin/p-function.sh"
        ;;
        
    "path")
        print_info "Setting up PATH-based installation..."
        current_dir=$(pwd)
        shell_config_line="export PATH=\"$current_dir:\$PATH\" && source $current_dir/scripts/p-function.sh"
        ;;
        
    "function")
        print_info "Setting up shell function only..."
        current_dir=$(pwd)
        shell_config_line="source $current_dir/scripts/p-function.sh"
        ;;
esac

echo

# Configure shell integration
print_info "Configuring shell integration..."

# Detect shell
if [ -n "$ZSH_VERSION" ]; then
    shell_config="$HOME/.zshrc"
    shell_name="zsh"
elif [ -n "$BASH_VERSION" ]; then
    shell_config="$HOME/.bashrc"
    shell_name="bash"
else
    print_warning "Could not detect shell type"
    print_info "Please manually add the following line to your shell configuration:"
    echo "  $shell_config_line"
    exit 0
fi

print_info "Detected $shell_name shell, config file: $shell_config"

# Check if already configured
if grep -q "p-function.sh" "$shell_config" 2>/dev/null; then
    print_warning "Shell integration already configured in $shell_config"
    print_info "Skipping automatic configuration"
else
    echo "" >> "$shell_config"
    echo "# Project Man integration" >> "$shell_config"
    echo "$shell_config_line" >> "$shell_config"
    print_success "Added shell integration to $shell_config"
fi

echo

# Final instructions
print_success "Installation completed!"
echo
print_info "To start using Project Man:"
echo "1. Restart your terminal or run: source $shell_config"
echo "2. Initialize a workspace: p init ~/workspace"
echo "3. Add repositories: p add user/repo"
echo "4. Navigate: p go repo-name"
echo

print_info "Available commands:"
echo "  p init <path>     - Initialize workspace"
echo "  p add <repo>      - Add repository"
echo "  p go [pattern]    - Navigate to repository (or workspace if no pattern)"
echo "  p list            - List repositories"
echo "  p sync            - Sync repositories"
echo "  p grep <pattern>  - Search across repositories"
echo "  p status          - Show workspace status"
echo

print_success "Enjoy using Project Man! 🚀"