#!/bin/bash

# Project Man Release Script
# Automatically increment version and create a new release

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Function to get the latest tag
get_latest_tag() {
    git fetch --tags 2>/dev/null || true
    local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    echo "$latest_tag"
}

# Function to increment version
increment_version() {
    local version="$1"
    local type="${2:-patch}"  # patch, minor, major
    
    # Remove 'v' prefix if present
    version=${version#v}
    
    # Split version into parts
    IFS='.' read -ra PARTS <<< "$version"
    local major=${PARTS[0]:-0}
    local minor=${PARTS[1]:-0}
    local patch=${PARTS[2]:-0}
    
    case "$type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch|*)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "v$major.$minor.$patch"
}

# Function to check if working directory is clean
check_working_directory() {
    if [ -n "$(git status --porcelain)" ]; then
        log_error "Working directory is not clean. Please commit or stash your changes."
        git status --short
        exit 1
    fi
}

# Function to push and create release
create_release() {
    local new_version="$1"
    
    log_info "Creating release $new_version..."
    
    # Push main branch
    log_info "Pushing main branch..."
    git push origin main
    
    # Create and push tag
    log_info "Creating tag $new_version..."
    git tag "$new_version"
    
    log_info "Pushing tag $new_version..."
    git push origin "$new_version"
    
    log_success "Release $new_version created successfully!"
    log_info "GitHub Actions will build the release automatically."
    log_info "Check the progress at: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
}

# Main function
main() {
    local version_type="${1:-patch}"
    
    log_info "🚀 Project Man Release Tool"
    echo ""
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not in a git repository!"
        exit 1
    fi
    
    # Check working directory
    check_working_directory
    
    # Get current version
    local current_version=$(get_latest_tag)
    log_info "Current version: $current_version"
    
    # Calculate new version
    local new_version=$(increment_version "$current_version" "$version_type")
    log_info "New version: $new_version"
    
    # Confirm with user
    echo ""
    read -p "Create release $new_version? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_release "$new_version"
        echo ""
        log_success "🎉 Release process completed!"
        log_info "Visit https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/releases to see your release"
    else
        log_warn "Release cancelled."
        exit 1
    fi
}

# Show help
show_help() {
    echo "Project Man Release Tool"
    echo ""
    echo "Usage: $0 [VERSION_TYPE]"
    echo ""
    echo "VERSION_TYPE:"
    echo "  patch   - Increment patch version (x.y.Z) [default]"
    echo "  minor   - Increment minor version (x.Y.0)"
    echo "  major   - Increment major version (X.0.0)"
    echo ""
    echo "Examples:"
    echo "  $0        # Create patch release (v1.2.3 -> v1.2.4)"
    echo "  $0 patch  # Create patch release (v1.2.3 -> v1.2.4)"
    echo "  $0 minor  # Create minor release (v1.2.3 -> v1.3.0)"
    echo "  $0 major  # Create major release (v1.2.3 -> v2.0.0)"
}

# Handle arguments
case "${1:-}" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    ""|patch|minor|major)
        main "$1"
        ;;
    *)
        log_error "Invalid version type: $1"
        echo ""
        show_help
        exit 1
        ;;
esac