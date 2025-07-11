# Contributing to Project Man

Thank you for your interest in contributing to Project Man! This guide will help you get started with development, testing, and submitting contributions.

## Table of Contents

- [Development Setup](#development-setup)
- [Project Architecture](#project-architecture)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Code Style](#code-style)
- [Submitting Changes](#submitting-changes)
- [Common Development Tasks](#common-development-tasks)

## Development Setup

### Prerequisites

- **Rust**: Install from [rustup.rs](https://rustup.rs/)
- **Git**: Required for repository operations
- **Terminal**: Bash or Zsh for shell integration testing

### Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/lockelee/project-man.git
   cd project-man
   ```

2. **Set up development environment:**
   ```bash
   # Quick setup - loads shell function for testing
   source ./dev-setup.sh
   
   # Or manually load the shell function
   source ./scripts/p-function.sh
   ```

3. **Build the project:**
   ```bash
   cargo build --release
   ```

4. **Test basic functionality:**
   ```bash
   # Test CLI help
   ./target/release/p-bin --help
   
   # Test with shell integration
   p --help
   ```

### Development Environment Details

- **Binary location**: `target/release/p-bin`
- **Shell function**: `scripts/p-function.sh`
- **Development script**: `dev-setup.sh`

The development environment uses the shell function which:
- Automatically finds the binary in `target/release/p-bin`
- Enables directory changing for `p go` and `p add` commands
- Provides auto-completion for commands

## Project Architecture

### Core Components

```
src/
├── main.rs              # Entry point and command routing
├── cli.rs               # Command-line argument parsing
├── error.rs             # Error types and handling
├── commands/            # Individual command implementations
│   ├── init.rs         # Workspace initialization
│   ├── add.rs          # Repository addition
│   ├── go.rs           # Navigation with fuzzy search
│   ├── list.rs         # Repository listing
│   ├── sync.rs         # Repository synchronization
│   └── ...
├── config/              # Configuration management
│   ├── global.rs       # Global user configuration
│   └── workspace.rs    # Workspace-specific registry
├── git/                 # Git operations
└── search/              # Fuzzy search and selection
```

### Key Design Principles

1. **Dual Configuration System**:
   - Global config: `~/.config/project-man/config.toml`
   - Workspace registry: `<workspace>/project-man.yml`

2. **Shell Command Integration**:
   - Use `std::process::Command` instead of git2 library
   - Leverage system SSH configuration
   - Real-time progress output

3. **Directory Organization**:
   - Structure: `workspace/host/user/repo`
   - Example: `workspace/github.com/rust-lang/rust`

## Development Workflow

### Building and Testing

```bash
# Development build
cargo build

# Release build (recommended for testing)
cargo build --release

# Check code without building
cargo check

# Run with arguments (for testing)
cargo run -- init /tmp/test-workspace
cargo run -- add rust-lang/rust
```

### Testing Commands

Create a test workspace to avoid affecting your real workspace:

```bash
# Initialize test workspace
p init /tmp/project-man-test

# Test repository operations
p add lockelee/project-man
p list
p go project-man
p status
```

### Shell Integration Testing

1. **Load development shell function:**
   ```bash
   source ./scripts/p-function.sh
   ```

2. **Test directory changing:**
   ```bash
   p go <pattern>    # Should change directory
   p add <repo>      # Should clone and change directory
   pwd               # Verify directory changed
   ```

3. **Test auto-completion:**
   ```bash
   p <TAB><TAB>      # Should show available commands
   ```

## Testing

### Manual Testing Checklist

Before submitting changes, test these core workflows:

#### Basic Commands
- [ ] `p init <path>` - Creates workspace and config files
- [ ] `p add <repo>` - Clones repository and updates registry
- [ ] `p list` - Shows repositories with status
- [ ] `p go <pattern>` - Navigates to repository
- [ ] `p go` (no pattern) - Navigates to workspace root
- [ ] `p status` - Shows workspace overview

#### Configuration
- [ ] `p config show` - Displays current configuration
- [ ] `p config set git.default_host gitlab.com` - Updates config
- [ ] `p config get git.default_host` - Retrieves config value

#### Repository Formats
- [ ] `p add user/repo` - GitHub shorthand
- [ ] `p add git@github.com:user/repo.git` - SSH URL
- [ ] `p add https://github.com/user/repo.git` - HTTPS URL

#### Error Handling
- [ ] Invalid repository URL
- [ ] Non-existent workspace
- [ ] Permission issues
- [ ] Network connectivity issues

### Test Environments

1. **Clean Environment Testing:**
   ```bash
   # Remove existing config
   rm -rf ~/.config/project-man
   
   # Test fresh installation
   p init /tmp/clean-test
   ```

2. **Multiple Workspace Testing:**
   ```bash
   # Test workspace switching
   p init /tmp/workspace1
   p init /tmp/workspace2
   # Verify correct workspace is used
   ```

## Code Style

### Rust Code Guidelines

1. **Follow Rust conventions:**
   ```bash
   cargo fmt        # Format code
   cargo clippy     # Lint code
   ```

2. **Error Handling:**
   - Use custom `ProjectManError` types
   - Convert to `anyhow::Error` in main()
   - Provide helpful error messages

3. **Async Functions:**
   - All command functions are async
   - Use `tokio::main` for async runtime

4. **Documentation:**
   - Add doc comments for public functions
   - Include examples in documentation
   - Update CLAUDE.md for significant changes

### Shell Script Guidelines

1. **Use bash syntax** for compatibility
2. **Include error handling** with `set -e` where appropriate
3. **Add comments** for complex logic
4. **Test on both bash and zsh**

## Submitting Changes

### Pull Request Process

1. **Fork the repository** on GitHub

2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes** following the guidelines above

4. **Test thoroughly** using the testing checklist

5. **Commit with clear messages:**
   ```bash
   git commit -m "Add fuzzy search improvements
   
   - Improve search algorithm accuracy
   - Add case-insensitive matching option
   - Fix interactive selection edge cases"
   ```

6. **Update documentation** if needed:
   - Update README.md for user-facing changes
   - Update CLAUDE.md for development changes
   - Update DESIGN.md for architectural changes

7. **Submit pull request** with:
   - Clear description of changes
   - Link to any related issues
   - Screenshots/examples if applicable

### Commit Message Guidelines

- Use imperative mood ("Add feature" not "Added feature")
- Include detailed description for complex changes
- Reference issues when applicable
- Keep first line under 50 characters

## Common Development Tasks

### Adding a New Command

1. **Create command file:**
   ```bash
   touch src/commands/new_command.rs
   ```

2. **Implement the command:**
   ```rust
   use crate::error::Result;
   
   pub async fn execute(args: &str) -> Result<()> {
       // Implementation
       Ok(())
   }
   ```

3. **Add to CLI definition** in `src/cli.rs`

4. **Add to command routing** in `src/main.rs`

5. **Add to module exports** in `src/commands/mod.rs`

### Modifying Configuration Schema

1. **Update structs** in `src/config/`
2. **Add migration logic** if needed
3. **Update default values**
4. **Test with existing config files**
5. **Update documentation**

### Debugging Common Issues

1. **Binary not found:**
   ```bash
   # Check binary exists
   ls -la target/release/p-bin
   
   # Rebuild if missing
   cargo build --release
   ```

2. **Shell function not working:**
   ```bash
   # Reload shell function
   source ./scripts/p-function.sh
   
   # Check function is loaded
   type p
   ```

3. **Directory not changing:**
   ```bash
   # Verify using shell function, not binary directly
   which p    # Should show function, not file path
   ```

### Performance Testing

For large repositories or many repositories:

```bash
# Test with many repositories
for i in {1..50}; do
    p add "test-user/repo-$i" 2>/dev/null || true
done

# Test search performance
time p go test

# Test list performance
time p list
```

## Getting Help

- **Issues**: Open an issue on GitHub for bugs or feature requests
- **Discussions**: Use GitHub Discussions for general questions
- **Documentation**: Check README.md, DESIGN.md, and CLAUDE.md

## License

By contributing to Project Man, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Project Man! 🚀