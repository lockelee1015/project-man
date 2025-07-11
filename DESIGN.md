# Project Man (p) - CLI Design Document

## Overview

Project Man is a Rust-based CLI tool designed to efficiently manage multiple code repositories locally. The tool provides a unified workspace for organizing, cloning, navigating, and maintaining Git repositories with a focus on developer productivity and ease of use.

## System Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                      CLI Interface (p)                      │
├─────────────────────────────────────────────────────────────┤
│  Command Parser  │  Config Manager  │  Repository Manager  │
├─────────────────────────────────────────────────────────────┤
│  Fuzzy Search    │  Git Operations  │  Directory Manager   │
├─────────────────────────────────────────────────────────────┤
│  File System     │  Shell Integration │  Error Handling    │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

- **Language**: Rust
- **CLI Framework**: `clap` (for argument parsing)
- **Fuzzy Search**: `fuzzy-matcher` or `skim`
- **Git Operations**: `git2` (libgit2 bindings)
- **Configuration**: `serde` + `toml` or `serde_json`
- **Shell Integration**: `dirs` (for home directory detection)
- **Terminal UI**: `crossterm` (for interactive selection)

## CLI Command Structure

### Primary Commands

#### `p init <workspace_path>`
**Purpose**: Initialize a new workspace directory
**Behavior**:
- Creates the workspace directory structure
- Initializes global configuration file (`~/.config/project-man/config.toml`)
- Creates workspace registry file (`<workspace>/project-man.yml`)
- Sets up default git host configuration

**Example**:
```bash
p init ~/workspace
p init /Users/john/dev
```

#### `p add <repository>`
**Purpose**: Clone and add repositories to workspace
**Supported formats**:
- `abc/foo` (uses default git host)
- `git@github.com:NomenAK/SuperClaude.git` (full SSH URL)
- `https://github.com/user/repo.git` (full HTTPS URL)

**Behavior**:
- Clones repository to appropriate directory structure
- Updates workspace registry with repository metadata
- Automatically navigates to cloned directory
- Handles directory conflicts gracefully

**Directory structure**: `/workspace/github.com/abc/foo`

**Examples**:
```bash
p add rust-lang/rust
p add git@github.com:NomenAK/SuperClaude.git
p add https://gitlab.com/user/project.git
```

#### `p go <repository_pattern>`
**Purpose**: Navigate to repositories with fuzzy search
**Behavior**:
- Supports fuzzy matching on repository names
- Displays interactive selection for multiple matches
- Changes to selected repository directory
- Integrates with shell for directory change

**Examples**:
```bash
p go rust          # Fuzzy match repositories containing "rust"
p go SuperClaude   # Navigate to SuperClaude repository
p go abc           # Show all repositories matching "abc"
```

#### `p list`
**Purpose**: List all managed repositories
**Behavior**:
- Shows repository name, path, and last updated
- Supports filtering and sorting options
- Displays repository status (clean, dirty, ahead/behind)

#### `p remove <repository_pattern>`
**Purpose**: Remove repositories from workspace
**Behavior**:
- Supports fuzzy matching
- Confirms before deletion
- Removes from workspace registry
- Optionally keeps or removes local files

**Examples**:
```bash
p remove rust-lang/rust
p remove SuperClaude
```

#### `p sync [repository_pattern]`
**Purpose**: Synchronize repositories (pull updates)
**Behavior**:
- Pulls latest changes from remote
- Supports syncing all repositories or specific patterns
- Reports sync status and conflicts
- Handles merge conflicts gracefully

**Examples**:
```bash
p sync              # Sync all repositories
p sync rust         # Sync repositories matching "rust"
p sync rust-lang/rust # Sync specific repository
```

#### `p grep <pattern> [repository_pattern]`
**Purpose**: Search across repositories
**Behavior**:
- Uses `rg` (ripgrep) as primary search tool
- Falls back to `grep` if `rg` not available
- Supports repository filtering
- Returns results with file paths and line numbers

**Examples**:
```bash
p grep "TODO"                    # Search all repositories
p grep "fn main" rust           # Search in Rust repositories
p grep "async" --type rust      # Search with file type filter
```

#### `p migrate <source_directory>`
**Purpose**: Import existing repositories into workspace
**Behavior**:
- Scans source directory for Git repositories
- Moves repositories to appropriate workspace structure
- Updates workspace registry with imported repositories
- Preserves Git history and remote configuration

**Examples**:
```bash
p migrate ~/old-projects
p migrate /Users/john/dev
```

### Utility Commands

#### `p config`
**Purpose**: Manage configuration settings
**Subcommands**:
- `p config show` - Display current configuration
- `p config set <key> <value>` - Set configuration value
- `p config get <key>` - Get configuration value

#### `p status`
**Purpose**: Show workspace status
**Behavior**:
- Shows workspace path and configuration
- Lists repository count and status
- Displays any issues or warnings

#### `p update`
**Purpose**: Update the CLI tool itself
**Behavior**:
- Checks for updates
- Downloads and installs latest version
- Preserves configuration during update

## Configuration Management

### Configuration File Structure

#### Global Configuration
**Location**: `~/.config/project-man/config.toml`

```toml
[workspace]
path = "/Users/john/workspace"
created_at = "2024-01-15T10:30:00Z"

[git]
default_host = "github.com"
default_protocol = "ssh"  # or "https"
ssh_key_path = "~/.ssh/id_rsa"

[search]
fuzzy_threshold = 0.6
max_results = 10
case_sensitive = false

[ui]
confirm_destructive_actions = true
use_colors = true
pager = "less"
```

#### Workspace Repository Registry
**Location**: `<workspace>/project-man.yml`

```yaml
# Project Man Workspace Registry
version: "1.0"
created_at: "2024-01-15T10:30:00Z"
updated_at: "2024-01-15T15:20:00Z"

repositories:
  rust-lang/rust:
    path: "github.com/rust-lang/rust"
    url: "https://github.com/rust-lang/rust.git"
    added_at: "2024-01-15T10:35:00Z"
    last_sync: "2024-01-15T15:20:00Z"
    tags: ["systems", "language"]
    
  NomenAK/SuperClaude:
    path: "github.com/NomenAK/SuperClaude"
    url: "git@github.com:NomenAK/SuperClaude.git"
    added_at: "2024-01-15T11:00:00Z"
    last_sync: "2024-01-15T14:45:00Z"
    tags: ["ai", "tools"]
    
  example/project:
    path: "gitlab.com/example/project"
    url: "https://gitlab.com/example/project.git"
    added_at: "2024-01-15T12:00:00Z"
    last_sync: "2024-01-15T14:30:00Z"
    tags: ["web", "frontend"]
```

### Configuration Schema

#### Global Configuration Schema
```rust
#[derive(Debug, Serialize, Deserialize)]
pub struct GlobalConfig {
    pub workspace: WorkspaceConfig,
    pub git: GitConfig,
    pub search: SearchConfig,
    pub ui: UiConfig,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct WorkspaceConfig {
    pub path: PathBuf,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GitConfig {
    pub default_host: String,
    pub default_protocol: String,
    pub ssh_key_path: Option<PathBuf>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SearchConfig {
    pub fuzzy_threshold: f64,
    pub max_results: usize,
    pub case_sensitive: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UiConfig {
    pub confirm_destructive_actions: bool,
    pub use_colors: bool,
    pub pager: String,
}
```

#### Workspace Registry Schema
```rust
#[derive(Debug, Serialize, Deserialize)]
pub struct WorkspaceRegistry {
    pub version: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub repositories: HashMap<String, RepositoryConfig>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RepositoryConfig {
    pub path: String,           // Relative path within workspace
    pub url: String,
    pub added_at: DateTime<Utc>,
    pub last_sync: Option<DateTime<Utc>>,
    pub tags: Vec<String>,
}
```

## Repository Management

### Directory Structure

```
workspace/
├── github.com/
│   ├── rust-lang/
│   │   └── rust/
│   ├── NomenAK/
│   │   └── SuperClaude/
│   └── user/
│       └── project/
├── gitlab.com/
│   └── user/
│       └── project/
└── bitbucket.org/
    └── user/
        └── project/
```

### Repository Operations

#### Clone Operation
1. Parse repository URL or shorthand
2. Determine target directory based on host/user/repo
3. Create necessary parent directories
4. Clone repository using `git2`
5. Update workspace registry (`project-man.yml`)
6. Change to repository directory

#### Repository Resolution
- **Shorthand**: `abc/foo` → `{default_host}/abc/foo`
- **Full SSH**: `git@github.com:user/repo.git` → `github.com/user/repo`
- **Full HTTPS**: `https://github.com/user/repo.git` → `github.com/user/repo`

### Git Integration

```rust
pub struct GitManager {
    config: Arc<Config>,
}

impl GitManager {
    pub fn clone_repository(&self, url: &str, path: &Path) -> Result<(), GitError> {
        // Implementation using git2
    }
    
    pub fn sync_repository(&self, path: &Path) -> Result<SyncResult, GitError> {
        // Pull latest changes
    }
    
    pub fn get_repository_status(&self, path: &Path) -> Result<RepoStatus, GitError> {
        // Check if clean, dirty, ahead/behind
    }
}
```

## Fuzzy Search and Navigation

### Search Implementation

```rust
pub struct FuzzyMatcher {
    repositories: Vec<Repository>,
    matcher: SkimMatcher,
}

impl FuzzyMatcher {
    pub fn search(&self, pattern: &str) -> Vec<SearchResult> {
        // Fuzzy matching implementation
    }
    
    pub fn interactive_select(&self, candidates: Vec<SearchResult>) -> Option<Repository> {
        // Interactive selection using crossterm
    }
}
```

### Search Strategy
1. **Exact match**: Direct repository name match
2. **Fuzzy match**: Pattern matching with scoring
3. **Path component match**: Match against path segments
4. **Tag match**: Match against repository tags

### Interactive Selection
- Display candidates with relevance scores
- Allow arrow key navigation
- Support Enter to select, Escape to cancel
- Show repository path and metadata

## Shell Integration

### Directory Change Implementation

Since CLI tools cannot directly change the parent shell's directory, we implement shell integration through:

1. **Shell Functions**: Provide shell-specific functions that wrap the CLI
2. **Output Parsing**: CLI outputs directory change commands for shell to execute
3. **Shell Detection**: Detect current shell and provide appropriate integration

**Bash/Zsh Integration**:
```bash
# Add to ~/.bashrc or ~/.zshrc
p() {
    local cmd="$1"
    if [ "$cmd" = "go" ] || [ "$cmd" = "add" ]; then
        local result=$(command p "$@" --output-cd)
        if [ $? -eq 0 ] && [ -n "$result" ]; then
            cd "$result"
        fi
    else
        command p "$@"
    fi
}
```

## Error Handling

### Error Categories
1. **Configuration Errors**: Invalid config, missing workspace
2. **Git Errors**: Clone failures, network issues, authentication
3. **File System Errors**: Permission issues, disk space
4. **User Input Errors**: Invalid repository names, missing arguments

### Error Response Strategy
```rust
#[derive(Debug, Error)]
pub enum ProjectManError {
    #[error("Configuration error: {0}")]
    Config(String),
    
    #[error("Git operation failed: {0}")]
    Git(String),
    
    #[error("Repository not found: {0}")]
    RepositoryNotFound(String),
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}
```

## Security Considerations

### SSH Key Management
- Support for custom SSH key paths
- Respect SSH agent configuration
- Secure handling of authentication credentials

### Repository Validation
- Validate repository URLs before cloning
- Prevent path traversal attacks
- Sanitize repository names for file system safety

## Performance Considerations

### Caching Strategy
- Cache repository metadata for faster lookups
- Lazy loading of repository status
- Efficient fuzzy search indexing

### Concurrent Operations
- Parallel repository synchronization
- Async Git operations where possible
- Progress reporting for long-running operations

## Testing Strategy

### Unit Tests
- Configuration management
- Repository URL parsing
- Fuzzy matching algorithms
- Git operations (mocked)

### Integration Tests
- Full workflow testing
- Shell integration testing
- File system operations
- Error handling scenarios

### Performance Tests
- Large repository set handling
- Fuzzy search performance
- Concurrent operation testing

## Development Phases

### Phase 1: Core Implementation
- Basic CLI structure with `clap`
- Configuration management
- Repository cloning and basic operations
- Simple navigation commands

### Phase 2: Advanced Features
- Fuzzy search implementation
- Interactive selection
- Shell integration
- Sync operations

### Phase 3: Enhanced Functionality
- Batch operations (grep, sync)
- Migration tools
- Advanced configuration options
- Performance optimizations

### Phase 4: Polish and Distribution
- Comprehensive testing
- Documentation
- Package distribution
- Shell completion scripts

## Success Metrics

- **Usability**: Single command repository management
- **Performance**: Sub-second response times for common operations
- **Reliability**: Robust error handling and recovery
- **Adoption**: Easy installation and setup process

## Future Enhancements

- **Team Collaboration**: Shared workspace configurations
- **Repository Templates**: Quick project scaffolding
- **Hooks**: Custom scripts for repository events
- **Web Interface**: Optional web dashboard for repository management
- **IDE Integration**: VS Code and other editor extensions