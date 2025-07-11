# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Project Man is a Rust-based CLI tool (`p`) for managing multiple Git repositories in a unified workspace. It provides repository organization, fuzzy search navigation, and batch operations across repositories.

## Essential Commands

### Build and Development
```bash
# Build for development
cargo build

# Build optimized release
cargo build --release

# Check for compile errors without building
cargo check

# Run with arguments
cargo run -- <command> [args]
# Example: cargo run -- init /tmp/workspace
```

### Testing the CLI
```bash
# Test built binary
./target/release/p --help

# Test specific commands
./target/release/p init /tmp/test-workspace
./target/release/p status
./target/release/p list
```

### Shell Integration Setup
```bash
# Source shell integration for directory changing
source shell-integration.sh

# Test shell integration
p go <pattern>  # Should change directory
p add <repo>    # Should clone and change directory
```

## Architecture Overview

### Core Module Structure
- **`src/main.rs`**: Entry point, command routing with async/await
- **`src/cli.rs`**: Clap-based command definitions and argument parsing
- **`src/commands/`**: Individual command implementations (init, add, go, list, etc.)
- **`src/config/`**: Configuration management with dual-file system
- **`src/git/`**: Git operations using git2 library with SSH authentication
- **`src/search/`**: Fuzzy search and interactive terminal selection
- **`src/error.rs`**: Custom error types using thiserror

### Configuration Architecture
The system uses a dual-configuration approach:
1. **Global Config** (`~/.config/project-man/config.toml`): User preferences, default git settings
2. **Workspace Registry** (`<workspace>/project-man.yml`): Repository metadata per workspace

This separation allows multiple workspaces with different repository collections while maintaining global user settings.

### Repository Organization
Repositories are organized as: `<workspace>/<git-host>/<user>/<repo>`
- Example: `/workspace/github.com/rust-lang/rust`
- Supports multiple git hosts (GitHub, GitLab, etc.)

### Key Data Flow
1. Commands load GlobalConfig to find workspace path
2. WorkspaceRegistry loads from `<workspace>/project-man.yml`
3. Git operations use SSH authentication with fallback strategies
4. Shell integration uses CD_TARGET output parsing for directory changes

## Critical Implementation Details

### SSH Authentication Strategy
The git2 library requires explicit SSH credential callbacks. The implementation:
1. Tries SSH agent first
2. Falls back to standard SSH key locations (`~/.ssh/id_rsa`, `~/.ssh/id_ed25519`)
3. Uses public key files when available
4. Applied to both clone and sync operations

### Shell Integration Pattern
Since CLI tools cannot change parent shell directories, the system uses:
- `--output-cd` flag for navigation commands
- `CD_TARGET:` prefix in output
- Shell function wrapper parses output and executes `cd`

### Error Handling
- Custom `ProjectManError` enum with thiserror
- Conversion to anyhow::Error in main() for CLI compatibility
- Structured error messages for different failure modes

### Async Design
- All command functions are async (using tokio)
- Allows for future concurrent operations (batch sync, parallel searches)
- Currently most operations are synchronous but wrapped in async

## Important Development Notes

### Repository Name Mapping
Repository names in the registry use underscore replacement: `"rust-lang/rust"` becomes `"rust-lang_rust"` as the key, while the path remains `"github.com/rust-lang/rust"`.

### Configuration Schema Evolution
The WorkspaceRegistry includes a version field for future schema migrations. Current version is "1.0".

### Git Operation Patterns
All Git operations should include the SSH authentication callback pattern. The pattern is implemented in both `clone_repository` and `sync_repository` methods.

### Interactive Selection
The fuzzy search module uses crossterm for terminal interaction with up/down arrow navigation and Enter/Escape handling.

## File System Layout
```
project-man/
├── src/
│   ├── commands/          # Individual command implementations
│   ├── config/           # Configuration management
│   ├── git/              # Git operations with SSH auth
│   └── search/           # Fuzzy search and terminal UI
├── shell-integration.sh  # Shell wrapper functions
├── DESIGN.md            # Comprehensive design documentation
└── Cargo.toml           # Dependencies and build config
```

## Testing Strategy
When testing new features:
1. Use temporary workspace: `p init /tmp/test-workspace`
2. Test with public repositories first
3. Verify shell integration by sourcing `shell-integration.sh`
4. Check both SSH and HTTPS repository URLs
5. Test error conditions (missing directories, invalid URLs)
```

## Development Guidelines

- Don't cargo build, I will do it by myself.