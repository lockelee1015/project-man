#!/bin/bash

# Project Man Shell Integration
# Add this to your ~/.bashrc or ~/.zshrc:
# source /path/to/project-man/shell-integration.sh

# Function to handle p command with directory change support
p() {
    local cmd="$1"
    
    # Commands that might change directory
    if [ "$cmd" = "go" ] || [ "$cmd" = "add" ]; then
        # Execute command and capture output
        local output=$(command p "$@" --output-cd 2>&1)
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
        command p "$@"
    fi
}

# Auto-completion for p command (bash)
if [ -n "$BASH_VERSION" ]; then
    _p_completion() {
        local cur prev opts
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        
        if [ $COMP_CWORD -eq 1 ]; then
            opts="init add go list remove sync grep migrate config status"
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        elif [ "$prev" = "config" ]; then
            opts="show set get"
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        fi
        
        return 0
    }
    
    complete -F _p_completion p
fi

# Auto-completion for p command (zsh)
if [ -n "$ZSH_VERSION" ]; then
    _p_completion() {
        local state
        _arguments '1: :->command' '*: :->args'
        
        case $state in
            command)
                _values 'p commands' \
                    'init[Initialize a new workspace]' \
                    'add[Add a repository]' \
                    'go[Navigate to repository]' \
                    'list[List repositories]' \
                    'remove[Remove repository]' \
                    'sync[Synchronize repositories]' \
                    'grep[Search in repositories]' \
                    'migrate[Migrate existing repositories]' \
                    'config[Manage configuration]' \
                    'status[Show workspace status]'
                ;;
            args)
                case $words[2] in
                    config)
                        _values 'config commands' \
                            'show[Show configuration]' \
                            'set[Set configuration value]' \
                            'get[Get configuration value]'
                        ;;
                esac
                ;;
        esac
    }
    
    compdef _p_completion p
fi

echo "✅ Project Man shell integration loaded!"
echo "💡 Use 'p go <pattern>' to navigate to repositories"
echo "💡 Use 'p add <repo>' to clone and navigate to new repositories"