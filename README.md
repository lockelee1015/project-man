# Project Man (p)

A powerful CLI tool for managing multiple Git repositories in a unified workspace.

[中文说明](#中文说明) | [English](#english)

## English

### Overview

Project Man (`p`) is a Rust-based command-line tool designed to efficiently manage multiple code repositories locally. It provides a unified workspace for organizing, cloning, navigating, and maintaining Git repositories with a focus on developer productivity and ease of use.

### Features

- 🚀 **Quick Repository Management**: Clone, sync, and organize repositories with simple commands
- 🔍 **Fuzzy Search Navigation**: Instantly navigate between repositories using fuzzy matching
- 📁 **Organized Directory Structure**: Automatic organization as `workspace/github.com/user/repo`
- 🔄 **Batch Operations**: Sync multiple repositories or search across all at once
- 🛠️ **Shell Integration**: Seamless directory changing with shell functions
- ⚙️ **Flexible Configuration**: Support for multiple Git hosts and protocols
- 🎯 **Interactive Selection**: User-friendly interactive menus for multiple matches

### Installation

#### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/lockelee/project-man/main/scripts/quick-install.sh | bash
```

#### Manual Installation

1. **Download the latest release:**
   - Go to [Releases](https://github.com/lockelee/project-man/releases)
   - Download the appropriate archive for your platform:
     - `project-man-x86_64-unknown-linux-gnu.tar.gz` (Linux x86_64)
     - `project-man-aarch64-unknown-linux-gnu.tar.gz` (Linux ARM64)
     - `project-man-x86_64-apple-darwin.tar.gz` (macOS Intel)
     - `project-man-aarch64-apple-darwin.tar.gz` (macOS Apple Silicon)

2. **Extract and install:**
   ```bash
   tar -xzf project-man-*.tar.gz
   cd project-man-*
   ./install.sh
   ```

#### From Source (Development)

```bash
# Clone the repository
git clone https://github.com/lockelee/project-man.git
cd project-man

# Build and install
cargo build --release
./install.sh
```

### Quick Start

```bash
# Initialize a workspace
p init ~/workspace

# Add repositories (supports various formats)
p add rust-lang/rust                              # GitHub shorthand
p add git@github.com:user/repo.git               # SSH URL
p add https://github.com/user/repo.git           # HTTPS URL

# Navigate to repositories
p go rust                                         # Fuzzy search
p go SuperClaude                                  # Direct match

# List all repositories with status
p list

# Sync repositories
p sync                                            # Sync all
p sync rust                                       # Sync matching pattern

# Search across repositories
p grep "TODO"                                     # Search all repos
p grep "async" rust                               # Search in specific repos

# Remove repositories
p remove old-project

# Show workspace status
p status

# Migrate existing repositories
p migrate ~/old-projects
```

### Directory Structure

Project Man organizes repositories in a clear, hierarchical structure:

```
workspace/
├── github.com/
│   ├── rust-lang/
│   │   └── rust/
│   ├── user/
│   │   └── project/
├── gitlab.com/
│   └── user/
│       └── project/
└── project-man.yml          # Workspace registry
```

### Configuration

#### Global Configuration
Location: `~/.config/project-man/config.toml`

```toml
[workspace]
path = "/Users/john/workspace"

[git]
default_host = "github.com"
default_protocol = "ssh"       # or "https"

[search]
fuzzy_threshold = 0.6
max_results = 10

[ui]
use_colors = true
confirm_destructive_actions = true
```

#### Workspace Registry
Location: `<workspace>/project-man.yml`

Contains metadata for all repositories in the workspace, including paths, URLs, tags, and sync timestamps.

### Shell Integration

The shell integration enables automatic directory changing:

```bash
# Add to ~/.bashrc or ~/.zshrc
source /path/to/project-man/shell-integration.sh

# Now these commands will change your directory:
p go rust-lang    # Changes to the rust-lang repository
p add new/repo    # Clones and changes to the new repository
```

### Command Reference

| Command | Description |
|---------|-------------|
| `p init <path>` | Initialize a new workspace |
| `p add <repo>` | Clone and add a repository |
| `p go <pattern>` | Navigate to a repository (fuzzy search) |
| `p list` | List all repositories with status |
| `p remove <pattern>` | Remove a repository from workspace |
| `p sync [pattern]` | Synchronize repositories |
| `p grep <pattern> [repo]` | Search across repositories |
| `p migrate <source>` | Import existing repositories |
| `p config show/set/get` | Manage configuration |
| `p status` | Show workspace status |

### Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed development guidelines, testing procedures, and submission process.

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 中文说明

### 概述

Project Man (`p`) 是一个基于 Rust 的命令行工具，专为高效管理本地多个代码仓库而设计。它提供了一个统一的工作区来组织、克隆、导航和维护 Git 仓库，专注于提升开发者的生产力和使用便利性。

### 特性

- 🚀 **快速仓库管理**: 通过简单命令克隆、同步和组织仓库
- 🔍 **模糊搜索导航**: 使用模糊匹配即时在仓库间导航
- 📁 **有序目录结构**: 自动组织为 `workspace/github.com/user/repo` 结构
- 🔄 **批量操作**: 一次性同步多个仓库或跨所有仓库搜索
- 🛠️ **Shell 集成**: 通过 shell 函数实现无缝目录切换
- ⚙️ **灵活配置**: 支持多个 Git 主机和协议
- 🎯 **交互式选择**: 对于多个匹配结果提供用户友好的交互菜单

### 安装

#### 快速安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/lockelee/project-man/main/scripts/quick-install.sh | bash
```

#### 手动安装

1. **下载最新版本:**
   - 访问 [Releases](https://github.com/lockelee/project-man/releases)
   - 下载适合你平台的压缩包:
     - `project-man-x86_64-unknown-linux-gnu.tar.gz` (Linux x86_64)
     - `project-man-aarch64-unknown-linux-gnu.tar.gz` (Linux ARM64)
     - `project-man-x86_64-apple-darwin.tar.gz` (macOS Intel)
     - `project-man-aarch64-apple-darwin.tar.gz` (macOS Apple Silicon)

2. **解压并安装:**
   ```bash
   tar -xzf project-man-*.tar.gz
   cd project-man-*
   ./install.sh
   ```

#### 从源码安装（开发用）

```bash
# 克隆仓库
git clone https://github.com/lockelee/project-man.git
cd project-man

# 构建并安装
cargo build --release
./install.sh
```

### 快速开始

```bash
# 初始化工作区
p init ~/workspace

# 添加仓库（支持多种格式）
p add rust-lang/rust                              # GitHub 简写
p add git@github.com:user/repo.git               # SSH URL
p add https://github.com/user/repo.git           # HTTPS URL

# 导航到仓库
p go rust                                         # 模糊搜索
p go SuperClaude                                  # 直接匹配

# 列出所有仓库及状态
p list

# 同步仓库
p sync                                            # 同步所有
p sync rust                                       # 同步匹配模式的仓库

# 跨仓库搜索
p grep "TODO"                                     # 搜索所有仓库
p grep "async" rust                               # 在特定仓库中搜索

# 移除仓库
p remove old-project

# 显示工作区状态
p status

# 迁移现有仓库
p migrate ~/old-projects
```

### 目录结构

Project Man 将仓库组织成清晰的层次结构：

```
workspace/
├── github.com/
│   ├── rust-lang/
│   │   └── rust/
│   ├── user/
│   │   └── project/
├── gitlab.com/
│   └── user/
│       └── project/
└── project-man.yml          # 工作区注册表
```

### 配置

#### 全局配置
位置: `~/.config/project-man/config.toml`

```toml
[workspace]
path = "/Users/john/workspace"

[git]
default_host = "github.com"
default_protocol = "ssh"       # 或 "https"

[search]
fuzzy_threshold = 0.6
max_results = 10

[ui]
use_colors = true
confirm_destructive_actions = true
```

#### 工作区注册表
位置: `<workspace>/project-man.yml`

包含工作区中所有仓库的元数据，包括路径、URL、标签和同步时间戳。

### Shell 集成

Shell 集成支持自动目录切换：

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
source /path/to/project-man/shell-integration.sh

# 现在这些命令将切换你的目录：
p go rust-lang    # 切换到 rust-lang 仓库
p add new/repo    # 克隆并切换到新仓库
```

### 命令参考

| 命令 | 描述 |
|---------|-------------|
| `p init <path>` | 初始化新工作区 |
| `p add <repo>` | 克隆并添加仓库 |
| `p go <pattern>` | 导航到仓库（模糊搜索） |
| `p list` | 列出所有仓库及状态 |
| `p remove <pattern>` | 从工作区移除仓库 |
| `p sync [pattern]` | 同步仓库 |
| `p grep <pattern> [repo]` | 跨仓库搜索 |
| `p migrate <source>` | 导入现有仓库 |
| `p config show/set/get` | 管理配置 |
| `p status` | 显示工作区状态 |

### 贡献

欢迎贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详细的开发指南、测试流程和提交规范。

### 许可证

本项目采用 MIT 许可证 - 详情请见 [LICENSE](LICENSE) 文件。