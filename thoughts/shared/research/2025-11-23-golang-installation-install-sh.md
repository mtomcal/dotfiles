---
date: 2025-11-23T06:40:12+0000
researcher: Claude
git_commit: 8ea8ce07358e72c4581e950093977447666c8592
branch: main
repository: dotfiles
topic: "Golang Installation for install.sh in 2025"
tags: [research, golang, install-sh, package-management, development-tools]
status: complete
last_updated: 2025-11-23
last_updated_by: Claude
related_research: thoughts/shared/research/2025-11-23-golang-neovim-setup.md
---

# Research: Golang Installation for install.sh in 2025

**Date**: 2025-11-23T06:40:12+0000
**Researcher**: Claude
**Git Commit**: 8ea8ce07358e72c4581e950093977447666c8592
**Branch**: main
**Repository**: dotfiles

## Research Question

What is the proper way to install Golang in 2025 for the install.sh script, considering best practices, platform compatibility (Ubuntu/macOS), version management, and integration with the existing Neovim setup?

## Summary

For install.sh integration in 2025, the recommended approach is a **hybrid strategy**:

1. **System Go Installation** - Install Go 1.24+ via package manager (brew on macOS) or official binary (Ubuntu)
2. **Optional Version Manager** - Offer to install `mise` for developers working with multiple Go versions
3. **PATH Configuration** - Ensure both `/usr/local/go/bin` and `$HOME/go/bin` are in PATH
4. **Verification** - Check Go version meets minimum requirements (1.24+ for gofumpt)
5. **Mason Integration** - Go installation must precede Neovim Mason configuration

**Critical Finding**: Go must be installed **before** Mason attempts to install gopls, gofumpt, goimports, and delve. The current install.sh installs Neovim first, then Mason packages - we need to add Go installation between these steps.

## Detailed Findings

### 1. Official Installation Methods (2025)

#### The Go Team's Recommendation

The official method from go.dev is manual binary installation:

**Linux (Official Method):**
```bash
# 1. Remove any previous installation
sudo rm -rf /usr/local/go

# 2. Download and extract (example: Go 1.25.4)
wget https://go.dev/dl/go1.25.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.25.4.linux-amd64.tar.gz

# 3. Add to PATH
export PATH=$PATH:/usr/local/go/bin

# 4. Verify
go version
```

**macOS (Official Method):**
- Download `.pkg` installer from go.dev/dl/
- Run installer (installs to `/usr/local/go`)
- PATH automatically updated

**Critical Warning**: "Do NOT untar the archive into an existing /usr/local/go tree. This is known to produce broken Go installations."

#### Architecture Detection

Go supports multiple architectures:
- **Linux**: `linux-amd64`, `linux-arm64`
- **macOS**: `darwin-amd64` (Intel), `darwin-arm64` (Apple Silicon)

The install.sh already has architecture detection logic for Neovim AppImage (lines 188-196) that can be reused.

### 2. Package Manager Installation

#### Homebrew (macOS) - RECOMMENDED for macOS

```bash
brew install go
```

**Pros:**
- Always provides recent versions (typically within days of release)
- Easy updates: `brew upgrade go`
- Handles dependencies automatically
- Supports version pinning: `brew install go@1.24`
- Integrates with existing install.sh brew workflow

**Cons:**
- May lag official releases by a few days
- Less control over exact point versions

**Verdict**: Excellent choice for macOS. Homebrew Go packages are well-maintained and current.

#### APT (Ubuntu) - NOT RECOMMENDED

```bash
sudo apt install golang-go
```

**Cons:**
- Ubuntu 22.04 LTS ships Go 1.18 (way too old)
- Ubuntu 24.04 LTS ships Go 1.21 (missing gofumpt support)
- No official Go PPA with latest versions
- Significantly outdated versions

**Verdict**: Do NOT use apt for Go installation. Use official binary method instead.

### 3. Version Management Tools

#### Native Go Toolchains (Go 1.21+)

Starting with Go 1.21, Go has built-in version management via `go.mod`:

```go
// go.mod
go 1.24      // Minimum Go version
toolchain go1.25.4  // Exact toolchain version
```

When a project uses this, Go automatically downloads and uses the correct version.

**Pros:**
- Built into Go core (no external tools)
- Ensures team consistency ("works on my machine" eliminated)
- Zero configuration for projects using go.mod

**Cons:**
- Requires base Go installation first (1.21+)
- Only works for projects with go.mod
- No global system-wide version switching

#### mise (Modern Version Manager)

**mise** (formerly rtx) is the recommended version manager for 2025:

```bash
# Install mise
curl https://mise.run | sh

# Install Go globally
mise use -g go@1.24.4

# Or per-project
cd myproject
mise use go@1.25.0
```

**Pros:**
- 2-5x faster than asdf (written in Rust)
- Compatible with asdf plugins and `.tool-versions`
- Supports multiple languages (Node, Python, Go, Ruby, etc.)
- Modern, actively maintained
- Parallel installation processing

**Cons:**
- Newer tool (less mature than asdf)
- Additional dependency

**Recommendation**: Offer mise as optional installation for developers working with multiple Go versions.

#### asdf-vm

**asdf** is the mature, established option:

```bash
# Install asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf

# Install Go plugin
asdf plugin add golang

# Install specific version
asdf install golang 1.24.4
asdf global golang 1.24.4
```

**Pros:**
- Mature, widely adopted
- Recently rewritten in Go (2-7x faster than old version)
- Large plugin ecosystem
- Strong community support

**Cons:**
- Unix-only (no native Windows)
- Requires bash/zsh configuration
- Need to run `asdf reshim golang` after `go install`

#### gvm (NOT RECOMMENDED)

**gvm** has known issues with newer Go versions:

From research: "only suitable to download older go versions but not suitable to install new ones"

**Verdict**: Avoid gvm for new setups in 2025.

### 4. Version Requirements Analysis

#### Minimum Go Version: **1.24**

The most restrictive requirement comes from **gofumpt**:

| Tool | Minimum Go Version |
|------|-------------------|
| gopls | 1.21+ (build version) |
| goimports | 1.21+ (estimated) |
| delve | 1.16+ |
| **gofumpt** | **1.24+** |

**Decision**: Target **Go 1.24** as minimum, recommend **Go 1.25.4** (latest stable as of Nov 2025).

#### Current Go Releases (2025)

- **Go 1.25.4** - Latest stable (Nov 5, 2025)
- **Go 1.24.x** - Supported
- **Go 1.23.x** - Supported
- **Go 1.22 and older** - End of life

### 5. Install.sh Integration Analysis

#### Current Install.sh Architecture

From lines 279-311, fnm (Fast Node Manager) installation follows this pattern:

```bash
1. Check if tool exists: command -v fnm
2. Install via official installer: curl -fsSL https://fnm.vercel.app/install | bash
3. Set up PATH for current session: export PATH="$HOME/.local/share/fnm:$PATH"
4. Install Node.js: fnm install --lts
5. Configure default version: fnm default lts-latest
6. Verify: node --version
```

We should follow a similar pattern for Go.

#### Recommended Installation Sequence

Current install.sh flow:
```
1. OS detection (48-68)
2. Package manager setup (73-89)
3. Dependencies (118-144)
4. Neovim installation (148-237)  ← Go should go BEFORE this
5. Oh My Zsh (243-273)
6. fnm + Node.js (279-311)
7. Tmux config (317-331)
8. Zsh config (337-350)
9. Neovim config (356-497)
10. Mason packages (509-516)  ← These require Go!
```

**Recommended new sequence:**
```
1. OS detection
2. Package manager setup
3. Dependencies
4. → Install Go (NEW SECTION)
5. Neovim installation
6. Oh My Zsh
7. fnm + Node.js
8. Tmux config
9. Zsh config
10. Neovim config
11. Mason packages (now works because Go exists)
```

#### Platform-Specific Installation Logic

**macOS:**
```bash
if [ "$OS" == "macos" ]; then
    if ! command -v go &> /dev/null; then
        print_info "Installing Go via Homebrew..."
        brew install go
        print_success "Go installed"
    else
        # Check version
        GO_VERSION=$(go version | grep -oP '\d+\.\d+' | head -1)
        if version_lt "$GO_VERSION" "1.24"; then
            print_warning "Go $GO_VERSION detected (recommended: 1.24+)"
            read -p "Upgrade to latest Go? (y/n) " -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                brew upgrade go
            fi
        else
            print_success "Go $GO_VERSION is already installed"
        fi
    fi
fi
```

**Ubuntu:**
```bash
if [ "$OS" == "ubuntu" ]; then
    if ! command -v go &> /dev/null; then
        print_info "Installing Go (official binary)..."

        # Detect architecture
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            GO_ARCH="amd64"
        elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            GO_ARCH="arm64"
        else
            print_error "Unsupported architecture: $ARCH"
            exit 1
        fi

        # Get latest stable version
        GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)
        GO_TARBALL="${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
        GO_URL="https://go.dev/dl/${GO_TARBALL}"

        # Download and install
        TMP_DIR=$(mktemp -d)
        cd "$TMP_DIR"
        wget "$GO_URL"

        # Remove old installation
        sudo rm -rf /usr/local/go

        # Extract new installation
        sudo tar -C /usr/local -xzf "$GO_TARBALL"

        # Cleanup
        cd - > /dev/null
        rm -rf "$TMP_DIR"

        print_success "Go installed to /usr/local/go"
    else
        # Version check logic (same as macOS)
    fi
fi
```

#### PATH Configuration

Go requires two directories in PATH:
1. `/usr/local/go/bin` - Go binary itself
2. `$HOME/go/bin` - Go-installed tools (gopls, delve, etc.)

**Add to zsh/.zshrc.custom:**
```bash
# Go configuration
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin
export GOPATH=$HOME/go
```

The install.sh already handles sourcing custom zsh config (lines 340-350), so this will work automatically.

### 6. Optional Version Manager Integration

For developers who need multiple Go versions:

```bash
print_header "Go Version Manager (Optional)"
echo ""
read -p "Install mise for Go version management? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! command -v mise &> /dev/null; then
        print_info "Installing mise..."
        curl https://mise.run | sh

        # Set up for current session
        export PATH="$HOME/.local/bin:$PATH"
        eval "$(mise activate bash)"

        print_success "mise installed"
        print_info "Note: Add 'eval \"\$(mise activate zsh)\"' to your shell config"

        # Ask if they want to use mise for Go
        read -p "Use mise to manage Go versions instead of system Go? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mise use -g go@latest
            print_success "Go latest version set via mise"
        fi
    else
        print_success "mise is already installed"
    fi
else
    print_info "Skipping mise installation"
fi
```

### 7. Verification and Testing

After Go installation, verify:

```bash
# Verify Go installation
if command -v go &> /dev/null; then
    GO_VERSION=$(go version)
    print_success "Go installed: $GO_VERSION"

    # Check GOPATH/bin exists
    mkdir -p "$HOME/go/bin"

    # Verify go env
    GOPATH=$(go env GOPATH)
    GOROOT=$(go env GOROOT)
    print_info "GOROOT: $GOROOT"
    print_info "GOPATH: $GOPATH"
else
    print_error "Go installation verification failed"
    exit 1
fi
```

### 8. Mason Integration

The research document at `/home/mtomcal/dotfiles/thoughts/shared/research/2025-11-23-golang-neovim-setup.md` shows Mason configuration at lines 509-516:

```lua
-- Install Mason packages for Python development
print_info "Installing Mason packages for Python development..."
if nvim --headless "+MasonInstall ruff pyright" +qa 2>/dev/null; then
    print_success "Mason packages installed (ruff, pyright)"
```

**Update this section** to include Go tools:

```bash
# Install Mason packages for development
print_info "Installing Mason packages..."

# Check if Go is available
if command -v go &> /dev/null; then
    MASON_PACKAGES="ruff pyright gopls delve gofumpt goimports"
    print_info "Installing Mason packages: $MASON_PACKAGES"
else
    MASON_PACKAGES="ruff pyright"
    print_warning "Go not found - skipping Go tools (gopls, delve, gofumpt, goimports)"
fi

if nvim --headless "+MasonInstall $MASON_PACKAGES" +qa 2>/dev/null; then
    print_success "Mason packages installed"
else
    print_warning "Mason package installation encountered an issue"
    print_info "You can manually install Mason packages later by running: :Mason in nvim"
fi
```

### 9. Security Considerations

#### Checksum Verification

For production systems, verify Go download checksums:

```bash
# Download Go tarball and checksum
wget "$GO_URL"
wget "https://go.dev/dl/${GO_TARBALL}.sha256"

# Verify checksum
echo "$(cat ${GO_TARBALL}.sha256)  ${GO_TARBALL}" | sha256sum -c -

if [ $? -eq 0 ]; then
    print_success "Checksum verification passed"
else
    print_error "Checksum verification failed"
    exit 1
fi
```

#### Official Go Vulnerability Database

After installation, recommend installing govulncheck:

```bash
print_info "Installing Go security tools..."
go install golang.org/x/vuln/cmd/govulncheck@latest
print_success "govulncheck installed (use: govulncheck ./...)"
```

### 10. Error Handling

Key error scenarios to handle:

1. **Architecture detection failure**
   ```bash
   if [ -z "$GO_ARCH" ]; then
       print_error "Could not detect system architecture"
       print_info "Please install Go manually from https://go.dev/dl/"
       exit 1
   fi
   ```

2. **Download failure**
   ```bash
   if ! wget "$GO_URL"; then
       print_error "Failed to download Go from $GO_URL"
       print_info "Please check your internet connection and try again"
       exit 1
   fi
   ```

3. **Permission issues**
   ```bash
   if ! sudo tar -C /usr/local -xzf "$GO_TARBALL"; then
       print_error "Failed to extract Go (permission denied?)"
       exit 1
   fi
   ```

4. **Version check failure**
   ```bash
   if ! go version &> /dev/null; then
       print_error "Go installed but 'go version' failed"
       print_info "Check PATH configuration: /usr/local/go/bin should be in PATH"
       exit 1
   fi
   ```

## Implementation Recommendations

### Recommended Install.sh Changes

**1. Add Go installation section** (insert after line 237, after Neovim installation):

```bash
# ===========================
# Install Go (Golang)
# ===========================

print_header "Installing Go"

# Function to compare versions
version_lt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$2" ]
}

if [ "$OS" == "macos" ]; then
    # macOS: Use Homebrew
    if ! command -v go &> /dev/null; then
        print_info "Installing Go via Homebrew..."
        brew install go
        print_success "Go installed"
    else
        GO_VERSION=$(go version | grep -oP '\d+\.\d+' | head -1)
        if version_lt "$GO_VERSION" "1.24"; then
            print_warning "Go $GO_VERSION detected (recommended: 1.24+)"
            read -p "Upgrade to latest Go? (y/n) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                brew upgrade go
                print_success "Go upgraded"
            fi
        else
            print_success "Go $GO_VERSION is already installed"
        fi
    fi
elif [ "$OS" == "ubuntu" ]; then
    # Ubuntu: Use official binary (apt versions are too old)
    if ! command -v go &> /dev/null; then
        print_info "Installing Go (official binary)..."

        # Detect architecture
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            GO_ARCH="amd64"
        elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            GO_ARCH="arm64"
        else
            print_error "Unsupported architecture: $ARCH"
            print_info "Please install Go manually from https://go.dev/dl/"
            exit 1
        fi

        # Get latest stable version
        print_info "Fetching latest Go version..."
        GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)

        if [ -z "$GO_VERSION" ]; then
            print_error "Failed to fetch Go version"
            exit 1
        fi

        GO_TARBALL="${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
        GO_URL="https://go.dev/dl/${GO_TARBALL}"

        print_info "Downloading Go ${GO_VERSION}..."

        # Create temp directory
        TMP_DIR=$(mktemp -d)
        cd "$TMP_DIR"

        # Download
        if ! wget -q --show-progress "$GO_URL"; then
            print_error "Failed to download Go"
            cd - > /dev/null
            rm -rf "$TMP_DIR"
            exit 1
        fi

        # Remove old installation (if exists)
        if [ -d "/usr/local/go" ]; then
            print_info "Removing previous Go installation..."
            sudo rm -rf /usr/local/go
        fi

        # Extract new installation
        print_info "Installing Go to /usr/local/go..."
        sudo tar -C /usr/local -xzf "$GO_TARBALL"

        # Cleanup
        cd - > /dev/null
        rm -rf "$TMP_DIR"

        print_success "Go ${GO_VERSION} installed"
    else
        GO_VERSION=$(go version | grep -oP '\d+\.\d+' | head -1)
        if version_lt "$GO_VERSION" "1.24"; then
            print_warning "Go $GO_VERSION detected (recommended: 1.24+)"
            print_info "Visit https://go.dev/dl/ to upgrade manually"
        else
            print_success "Go $GO_VERSION is already installed"
        fi
    fi
fi

# Verify Go installation
if command -v go &> /dev/null; then
    GO_FULL_VERSION=$(go version)
    print_success "Go verified: $GO_FULL_VERSION"

    # Create GOPATH bin directory
    mkdir -p "$HOME/go/bin"

    # Add Go to PATH for this session
    export PATH=$PATH:/usr/local/go/bin
    export PATH=$PATH:$HOME/go/bin
    export GOPATH=$HOME/go
else
    print_error "Go installation verification failed"
    exit 1
fi

# Optional: Install govulncheck for security scanning
read -p "Install govulncheck (Go vulnerability scanner)? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installing govulncheck..."
    go install golang.org/x/vuln/cmd/govulncheck@latest
    print_success "govulncheck installed (use: govulncheck ./...)"
fi
```

**2. Update zsh/.zshrc.custom** (add Go PATH configuration):

```bash
# Go configuration
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin
export GOPATH=$HOME/go
```

**3. Update Mason installation** (lines 509-516):

```bash
# Install Mason packages for development
print_info "Installing Mason packages..."

# Build package list based on available tools
MASON_PACKAGES="stylua"  # Lua formatter (always installed)

# Python tools
MASON_PACKAGES="$MASON_PACKAGES ruff pyright"

# Go tools (only if Go is installed)
if command -v go &> /dev/null; then
    MASON_PACKAGES="$MASON_PACKAGES gopls delve gofumpt goimports"
    print_info "Go detected - including Go development tools"
else
    print_warning "Go not found - skipping Go tools"
fi

print_info "Installing Mason packages: $MASON_PACKAGES"

if nvim --headless "+MasonInstall $MASON_PACKAGES" +qa 2>/dev/null; then
    print_success "Mason packages installed"
else
    print_warning "Mason package installation encountered an issue"
    print_info "You can manually install Mason packages later by running: :Mason in nvim"
fi
```

**4. Update completion message** (lines 833-843):

```bash
print_info "What was installed:"
echo "  ✓ Tmux with vim-style bindings"
echo "  ✓ Neovim with official kickstart.nvim"
echo "  ✓ Custom config directory (~/dotfiles/nvim/custom)"
echo "  ✓ Zsh with Oh My Zsh"
echo "  ✓ Go 1.24+ (Golang)"
echo "  ✓ fnm (Fast Node Manager) + Node.js LTS"
echo "  ✓ Claude Code custom commands and agents"
echo "  ✓ OpenCode CLI with custom commands"
echo "  ✓ wtp (git worktree manager for parallel AI workflows)"
echo "  ✓ All required dependencies"
```

### Optional: Version Manager Integration

If offering mise as an option:

```bash
# ===========================
# Go Version Manager (Optional)
# ===========================

print_header "Go Version Manager (Optional)"
echo ""
print_info "mise allows managing multiple Go versions per-project"
read -p "Install mise for Go version management? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! command -v mise &> /dev/null; then
        print_info "Installing mise..."
        curl https://mise.run | sh

        # Add to PATH for this session
        export PATH="$HOME/.local/bin:$PATH"

        print_success "mise installed"
        print_info "Add to your shell: eval \"\$(mise activate zsh)\""
    else
        print_success "mise is already installed"
    fi
fi
```

## Code References

Files to modify:
- `/home/mtomcal/dotfiles/install.sh:237` - Insert Go installation section after Neovim
- `/home/mtomcal/dotfiles/install.sh:509-516` - Update Mason package installation
- `/home/mtomcal/dotfiles/install.sh:833-843` - Update completion message
- `/home/mtomcal/dotfiles/zsh/.zshrc.custom` - Add Go PATH configuration

Reference implementations:
- `/home/mtomcal/dotfiles/install.sh:279-311` - fnm installation pattern (similar structure)
- `/home/mtomcal/dotfiles/install.sh:148-237` - Neovim AppImage installation (architecture detection)
- `/home/mtomcal/dotfiles/install.sh:97-116` - install_package function (platform handling)

## Architecture Insights

### Install.sh Design Patterns

The install.sh follows these patterns:

1. **Platform detection** (lines 48-68) - Detect OS, set PACKAGE_MANAGER variable
2. **Install functions** (lines 97-116) - Reusable install_package() function
3. **Version checking** - Check if tool exists, verify version, offer upgrade
4. **Backup strategy** - Backup existing configs with timestamps before replacing
5. **User prompts** - Interactive prompts for optional features
6. **PATH management** - Export PATH for current session, update shell configs
7. **Verification** - Always verify installation with `--version` or equivalent

Go installation should follow these same patterns for consistency.

### Dependency Chain

Current dependency order:
```
System Packages → Neovim → Zsh → fnm → Node.js → Configs → Mason Packages
```

New dependency order:
```
System Packages → Go → Neovim → Zsh → fnm → Node.js → Configs → Mason Packages
                  ↑                                                    ↑
                  └────────────────────────────────────────────────────┘
                  Go must exist before Mason installs gopls, delve, etc.
```

### Platform-Specific Considerations

**macOS:**
- Homebrew provides excellent Go support
- Automatic PATH configuration
- Easy updates via `brew upgrade`
- No sudo required for installation

**Ubuntu:**
- APT packages too outdated (avoid)
- Official binary installation requires sudo
- Manual PATH configuration needed
- Architecture detection critical (x86_64 vs arm64)

## Related Research

- `/home/mtomcal/dotfiles/thoughts/shared/research/2025-11-23-golang-neovim-setup.md` - Neovim Go development setup (gopls, tools, configuration)

## Open Questions

1. Should we make Go installation optional or required?
   - **Recommendation**: Required if user wants full development setup

2. Should we offer mise by default or only on request?
   - **Recommendation**: Optional, prompt user

3. Should we pre-install Go tools via `go install` or let Mason handle it?
   - **Recommendation**: Let Mason handle it (consistent with Python tools)

4. What should happen if Go installation fails?
   - **Recommendation**: Continue with warning, skip Mason Go tools

5. Should we verify Go checksums for security?
   - **Recommendation**: Not by default (slows installation), but document for production use

## Next Steps

To implement Go installation in install.sh:

1. Add Go installation section after Neovim installation (line 237)
2. Update zsh/.zshrc.custom with Go PATH configuration
3. Update Mason package installation to include Go tools conditionally
4. Test on both Ubuntu and macOS
5. Update AGENTS.md documentation with Go installation details
6. Consider adding `/worktree-create` test case for Go projects
