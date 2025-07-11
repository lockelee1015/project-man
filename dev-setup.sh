#!/bin/bash

# Development setup script for Project Man
# This loads the development version of the shell function

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shell function
source "$SCRIPT_DIR/scripts/p-function.sh"

echo "✅ Project Man development environment loaded!"
echo "💡 Using binary: $SCRIPT_DIR/target/release/p-bin"
echo "💡 Try: p go, p list, p status"