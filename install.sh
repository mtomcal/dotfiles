#!/bin/bash

# ===========================
# Dotfiles Installation Script
# ===========================
# Modular menu-driven installer for development environment
# Supports: Ubuntu/Debian (apt) and macOS (homebrew)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Get the dotfiles directory
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Global variables
OS=""
PACKAGE_MANAGER=""
SELECTED_MODULES=()
FAILED_MODULES=()
# Modules whose install/configure function actually ran and succeeded.
COMPLETED_MODULES=()
CODEX_CONFIG_TEMPLATE_MODE="preserve"
# Installation profile requested on the command line; expanded after OS detection.
REQUESTED_PROFILE=""
# Runtime-only code-server bind override; never written to a tracked file.
CODE_SERVER_BIND=""

# ===========================
# Core Functions
# ===========================

detect_os() {
    print_info "Detecting operating system..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &> /dev/null; then
            OS="ubuntu"
            PACKAGE_MANAGER="apt"
            print_success "Detected: Ubuntu/Debian Linux"
        else
            print_error "Linux detected but apt not found. This script requires Ubuntu/Debian."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
        print_success "Detected: macOS"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

setup_package_manager() {
    if [ "$OS" == "macos" ]; then
        if ! command -v brew &> /dev/null; then
            print_info "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Add Homebrew to PATH (for Apple Silicon Macs)
            if [[ $(uname -m) == 'arm64' ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi

            print_success "Homebrew installed"
        else
            print_success "Homebrew is already installed"
        fi
    fi
}

update_package_manager() {
    print_info "Updating package manager..."
    if [ "$PACKAGE_MANAGER" == "apt" ]; then
        sudo apt update
    elif [ "$PACKAGE_MANAGER" == "brew" ]; then
        brew update
    fi
}

modules_require_package_manager_update() {
    local module

    for module in "$@"; do
        case "$module" in
            "base_tools")
                return 0
                ;;
        esac
    done

    return 1
}

install_package() {
    local package=$1
    local brew_name=${2:-$package}

    if [ "$PACKAGE_MANAGER" == "apt" ]; then
        if ! dpkg -l | grep -q "^ii  $package "; then
            print_info "Installing $package..."
            sudo apt install -y "$package"
        else
            print_success "$package is already installed"
        fi
    elif [ "$PACKAGE_MANAGER" == "brew" ]; then
        if ! brew list "$brew_name" &> /dev/null; then
            print_info "Installing $brew_name..."
            brew install "$brew_name"
        else
            print_success "$brew_name is already installed"
        fi
    fi
}

version_lt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$2" ]
}

# ===========================
# Module Installation Functions
# ===========================

install_base_tools() {
    print_header "Installing Base Tools"

    # Install essential packages
    install_package "git" "git"
    install_package "curl" "curl"
    install_package "tmux" "tmux"
    install_package "ripgrep" "ripgrep"
    install_package "zsh" "zsh"
    install_package "jq" "jq"
    install_package "gh" "gh"

    # Platform-specific packages
    if [ "$OS" == "ubuntu" ]; then
        install_package "build-essential"
        install_package "fd-find"
        install_package "xclip"
        install_package "python3-venv"
    elif [ "$OS" == "macos" ]; then
        install_package "gcc" "gcc"
        install_package "fd" "fd"
        install_package "tree-sitter-cli" "tree-sitter-cli"  # CLI split from tree-sitter library in 0.26+
    fi

    print_success "Base tools installed"
}

install_neovim() {
    print_header "Installing Neovim"

    if [ "$OS" == "ubuntu" ]; then
        # Check if nvim exists and get version
        if command -v nvim &> /dev/null; then
            NVIM_VERSION=$(nvim --version 2>/dev/null | head -n1 | sed 's/.*v\([0-9]*\.[0-9]*\).*/\1/' || echo "0.0")
        else
            NVIM_VERSION="0.0"
        fi

        if version_lt "$NVIM_VERSION" "0.12"; then
            print_warning "Neovim version is $NVIM_VERSION (required: 0.12+)"
            print_info "Installing latest stable Neovim via AppImage..."

            # Remove any existing apt-installed neovim
            if dpkg -l | grep -q "^ii  neovim "; then
                print_info "Removing apt-installed neovim..."
                sudo apt remove -y neovim neovim-runtime 2>/dev/null || true
            fi

            # Get latest stable release version
            LATEST_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases | grep '"tag_name"' | grep -v 'nightly\|stable' | head -1 | cut -d'"' -f4)

            if [ -z "$LATEST_VERSION" ]; then
                print_error "Failed to fetch latest Neovim version"
                return 1
            fi

            print_info "Downloading Neovim $LATEST_VERSION..."

            TMP_DIR=$(mktemp -d)
            cd "$TMP_DIR"

            # Detect architecture
            ARCH=$(uname -m)
            if [ "$ARCH" = "x86_64" ]; then
                APPIMAGE_NAME="nvim-linux-x86_64.appimage"
            elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
                APPIMAGE_NAME="nvim-linux-arm64.appimage"
            else
                print_error "Unsupported architecture: $ARCH"
                return 1
            fi

            curl -LO "https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/${APPIMAGE_NAME}"
            chmod +x "$APPIMAGE_NAME"

            # Install to /usr/local/bin or ~/.local/bin
            if [ -w /usr/local/bin ]; then
                mv "$APPIMAGE_NAME" /usr/local/bin/nvim
                print_success "Neovim installed to /usr/local/bin/nvim"
            else
                mkdir -p "$HOME/.local/bin"
                mv "$APPIMAGE_NAME" "$HOME/.local/bin/nvim"
                print_success "Neovim installed to ~/.local/bin/nvim"

                if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                    print_info "Note: Add ~/.local/bin to your PATH if not already done"
                fi
            fi

            cd - > /dev/null
            rm -rf "$TMP_DIR"

            INSTALLED_VERSION=$(nvim --version | head -n1 | sed 's/.*v\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/')
            print_success "Neovim $INSTALLED_VERSION installed successfully"
        else
            print_success "Neovim $NVIM_VERSION is already installed (meets requirements >= 0.12)"
        fi
    elif [ "$OS" == "macos" ]; then
        # Check if nvim exists and get version
        if command -v nvim &> /dev/null; then
            NVIM_VERSION=$(nvim --version 2>/dev/null | head -n1 | sed 's/.*v\([0-9]*\.[0-9]*\).*/\1/' || echo "0.0")
        else
            NVIM_VERSION="0.0"
        fi

        if version_lt "$NVIM_VERSION" "0.12"; then
            print_warning "Neovim version is $NVIM_VERSION (required: 0.12+)"
            print_info "Installing/upgrading Neovim via Homebrew..."
            if ! brew list neovim &> /dev/null; then
                brew install neovim
            else
                brew upgrade neovim
            fi
        else
            print_success "Neovim $NVIM_VERSION is already installed"
        fi
    fi
}

configure_neovim() {
    print_header "Configuring Neovim"

    # Check if neovim is installed
    if ! command -v nvim &> /dev/null; then
        print_warning "Neovim not found. Installing Neovim first..."
        install_neovim || return 1
    fi

    # Handle existing neovim config
    if [ -d "$HOME/.config/nvim" ]; then
        if [ -d "$HOME/.config/nvim/.git" ]; then
            REMOTE_URL=$(cd "$HOME/.config/nvim" && git remote get-url origin 2>/dev/null || echo "")

            if [[ "$REMOTE_URL" == *"nvim-lua/kickstart.nvim"* ]]; then
                print_info "Updating kickstart.nvim to latest version..."
                cd "$HOME/.config/nvim"
                git fetch origin
                git reset --hard origin/master
                print_success "Kickstart.nvim updated"
            else
                print_warning "Existing nvim config is not official kickstart.nvim"
                TIMESTAMP=$(date +%Y%m%d_%H%M%S)
                mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$TIMESTAMP"
                print_success "Backed up to ~/.config/nvim.backup.$TIMESTAMP"

                print_info "Cloning official kickstart.nvim..."
                git clone https://github.com/nvim-lua/kickstart.nvim.git "$HOME/.config/nvim"
                print_success "Official kickstart.nvim cloned"
            fi
        else
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$TIMESTAMP"
            print_success "Backed up to ~/.config/nvim.backup.$TIMESTAMP"

            print_info "Cloning official kickstart.nvim..."
            git clone https://github.com/nvim-lua/kickstart.nvim.git "$HOME/.config/nvim"
            print_success "Official kickstart.nvim cloned"
        fi
    else
        print_info "Cloning official kickstart.nvim..."
        mkdir -p "$HOME/.config"
        git clone https://github.com/nvim-lua/kickstart.nvim.git "$HOME/.config/nvim"
        print_success "Official kickstart.nvim cloned"
    fi

    # Create custom config directory
    mkdir -p "$DOTFILES_DIR/nvim/custom/plugins"

    # Create placeholder README if it doesn't exist
    if [ ! -f "$DOTFILES_DIR/nvim/custom/README.md" ]; then
        cat > "$DOTFILES_DIR/nvim/custom/README.md" << 'EOF'
# Custom Neovim Configuration

This directory contains your personal neovim customizations that layer on top of kickstart.nvim.

## Structure

- `plugins/` - Custom plugin specifications
- `init.lua` - Custom initialization (optional)
- Any other lua modules you want to add

## How It Works

Kickstart.nvim automatically loads configurations from `~/.config/nvim/lua/custom/`.
This directory is symlinked to your dotfiles, so changes here are version controlled.

The `plugins/init.lua` file auto-loads all `.lua` files in the `plugins/` directory.

## Adding Custom Plugins

Create a new file in `plugins/` directory using vim.pack format:

```lua
-- plugins/my-plugin.lua
vim.pack.add({
  { src = 'https://github.com/author/plugin-name' },
})

-- Configure after adding
require('plugin-name').setup({
  -- your options here
})

-- Add keymaps
vim.keymap.set('n', '<leader>xx', '<cmd>PluginCommand<CR>', { desc = 'My Plugin' })
```

## Adding Custom Keymaps

You can add custom keymaps in `init.lua` or create separate module files.
EOF
    fi

    # Create symlink for custom configs
    mkdir -p "$HOME/.config/nvim/lua"

    if [ -L "$HOME/.config/nvim/lua/custom" ]; then
        rm "$HOME/.config/nvim/lua/custom"
    elif [ -d "$HOME/.config/nvim/lua/custom" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.config/nvim/lua/custom" "$HOME/.config/nvim/lua/custom.backup.$TIMESTAMP"
        print_warning "Backed up existing custom config"
    fi

    ln -sf "$DOTFILES_DIR/nvim/custom" "$HOME/.config/nvim/lua/custom"
    print_success "Custom neovim config linked"

    # Enable custom plugins in kickstart.nvim
    if [ -f "$HOME/.config/nvim/init.lua" ]; then
        # Handle new kickstart.nvim (vim.pack) pattern: -- require 'custom.plugins'
        if grep -q "^  -- require 'custom\.plugins'" "$HOME/.config/nvim/init.lua"; then
            if [ "$OS" == "macos" ]; then
                sed -i '' "s/^  -- require 'custom\.plugins'/  require 'custom.plugins'/" "$HOME/.config/nvim/init.lua"
            else
                sed -i "s/^  -- require 'custom\.plugins'/  require 'custom.plugins'/" "$HOME/.config/nvim/init.lua"
            fi
            print_success "Custom plugin loading enabled (vim.pack format)"
        # Handle old kickstart.nvim (lazy.nvim) pattern: -- { import = 'custom.plugins' },
        elif grep -q "^  -- { import = 'custom\.plugins' }," "$HOME/.config/nvim/init.lua"; then
            if [ "$OS" == "macos" ]; then
                sed -i '' "s/^  -- { import = 'custom\.plugins' },/  { import = 'custom.plugins' },/" "$HOME/.config/nvim/init.lua"
            else
                sed -i "s/^  -- { import = 'custom\.plugins' },/  { import = 'custom.plugins' },/" "$HOME/.config/nvim/init.lua"
            fi
            print_success "Custom plugin loading enabled (lazy.nvim format)"
        elif grep -q "^  require 'custom\.plugins'" "$HOME/.config/nvim/init.lua"; then
            print_success "Custom plugin loading already enabled (vim.pack format)"
        elif grep -q "^  { import = 'custom\.plugins' }," "$HOME/.config/nvim/init.lua"; then
            print_success "Custom plugin loading already enabled (lazy.nvim format)"
        else
            print_warning "Could not find custom plugins directive in init.lua"
            print_info "Manually add: require('custom.plugins') near the end of init.lua"
        fi

        # Fix nvim-treesitter.configs deprecated API (nvim-treesitter changed from .configs to root module)
        if grep -q "main = 'nvim-treesitter\.configs'" "$HOME/.config/nvim/init.lua"; then
            print_info "Fixing nvim-treesitter.configs deprecated API..."
            if [ "$OS" == "macos" ]; then
                sed -i '' "s/main = 'nvim-treesitter\.configs'/main = 'nvim-treesitter'/" "$HOME/.config/nvim/init.lua"
            else
                sed -i "s/main = 'nvim-treesitter\.configs'/main = 'nvim-treesitter'/" "$HOME/.config/nvim/init.lua"
            fi
            print_success "Fixed nvim-treesitter API compatibility"
        fi
    fi

    # Clean cache on fresh installation (check both lazy.nvim and vim.pack paths)
    if [ ! -d "$HOME/.local/share/nvim/lazy" ] && [ ! -d "$HOME/.local/share/nvim/site/pack/core/opt" ]; then
        print_info "Fresh installation detected - cleaning neovim cache..."
        rm -rf "$HOME/.local/share/nvim"
        rm -rf "$HOME/.local/state/nvim"
        rm -rf "$HOME/.cache/nvim"
    else
        print_info "Preserving existing Mason packages and plugin cache"
        rm -rf "$HOME/.cache/nvim"
    fi

    # Ensure tree-sitter CLI is available for building parsers on Ubuntu
    if [ "$OS" == "ubuntu" ]; then
        if ! command -v tree-sitter &> /dev/null; then
            print_info "Installing tree-sitter CLI (for nvim-treesitter parsers)..."
            npm install -g tree-sitter-cli@latest 2>/dev/null || print_warning "tree-sitter CLI install failed (pre-built parsers may be used)"
        fi
    fi

    # Install plugins (vim.pack installs automatically on startup)
    print_info "Installing neovim plugins (vim.pack auto-install)..."
    if nvim --headless +qa 2>&1; then
        print_success "Neovim plugins installed"
    else
        print_warning "Plugin installation may require manual intervention"
        print_info "Run: nvim --headless +qa"
    fi

    # Update treesitter parsers
    print_info "Updating treesitter parsers..."
    if nvim --headless "+TSUpdateSync" +qa 2>/dev/null; then
        print_success "Treesitter parsers updated"
    else
        print_warning "Treesitter parser update encountered an issue"
    fi

    # Install Mason packages (base language support)
    print_info "Installing Mason packages..."
    MASON_PACKAGES="stylua ruff pyright prettier eslint_d"

    if nvim --headless "+MasonInstall $MASON_PACKAGES" +qa 2>/dev/null; then
        print_success "Mason packages installed"
    else
        print_warning "Mason packages may require manual installation"
        print_info "Run: :Mason in nvim"
    fi

    # Note about Go tools
    if command -v go &> /dev/null; then
        print_info "Go detected - use 'golang_full' module to install Go LSP tools"
    fi
}

install_golang() {
    print_header "Installing Go"

    if [ "$OS" == "macos" ]; then
        if ! command -v go &> /dev/null; then
            print_info "Installing Go via Homebrew..."
            brew install go
            print_success "Go installed"
        else
            GO_VERSION=$(go version | sed 's/.*go\([0-9]*\.[0-9]*\).*/\1/')
            if version_lt "$GO_VERSION" "1.24"; then
                print_warning "Go $GO_VERSION detected (recommended: 1.24+)"
                if brew list go &> /dev/null; then
                    print_info "Upgrading Go via Homebrew..."
                    brew upgrade go
                    print_success "Go upgraded"
                else
                    print_info "Installing Go via Homebrew..."
                    brew install go
                    print_success "Go installed"
                fi
            else
                print_success "Go $GO_VERSION is already installed"
            fi
        fi
    elif [ "$OS" == "ubuntu" ]; then
        if ! command -v go &> /dev/null; then
            print_info "Installing Go (official binary)..."

            ARCH=$(uname -m)
            if [ "$ARCH" = "x86_64" ]; then
                GO_ARCH="amd64"
            elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
                GO_ARCH="arm64"
            else
                print_error "Unsupported architecture: $ARCH"
                return 1
            fi

            GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)
            if [ -z "$GO_VERSION" ]; then
                print_error "Failed to fetch Go version"
                return 1
            fi

            GO_TARBALL="${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
            GO_URL="https://go.dev/dl/${GO_TARBALL}"

            print_info "Downloading Go ${GO_VERSION}..."
            TMP_DIR=$(mktemp -d)
            cd "$TMP_DIR"

            if ! wget -q --show-progress "$GO_URL"; then
                print_error "Failed to download Go"
                cd - > /dev/null
                rm -rf "$TMP_DIR"
                return 1
            fi

            if [ -d "/usr/local/go" ]; then
                print_info "Removing previous Go installation..."
                sudo rm -rf /usr/local/go
            fi

            print_info "Installing Go to /usr/local/go..."
            sudo tar -C /usr/local -xzf "$GO_TARBALL"

            cd - > /dev/null
            rm -rf "$TMP_DIR"

            print_success "Go ${GO_VERSION} installed"
        else
            GO_VERSION=$(go version | sed 's/.*go\([0-9]*\.[0-9]*\).*/\1/')
            if version_lt "$GO_VERSION" "1.24"; then
                print_warning "Go $GO_VERSION detected (recommended: 1.24+)"
            else
                print_success "Go $GO_VERSION is already installed"
            fi
        fi
    fi

    # Clear any inherited GOROOT that could poison the go binary
    unset GOROOT

    # On macOS, ensure Homebrew's go is first on PATH
    if [ "$OS" == "macos" ]; then
        BREW_GO_BIN="$(brew --prefix go 2>/dev/null)/bin"
        if [[ -d "$BREW_GO_BIN" ]]; then
            export PATH="$BREW_GO_BIN:$PATH"
        fi
    fi

    # Verify installation
    if command -v go &> /dev/null; then
        GO_FULL_VERSION=$(go version)
        print_success "Go verified: $GO_FULL_VERSION"

        export GOPATH="$HOME/go-workspace"
        mkdir -p "$GOPATH/bin"
        if [ "$OS" == "ubuntu" ] && [[ -d "/usr/local/go/bin" ]]; then
            export PATH="/usr/local/go/bin:$PATH"
        fi
        export PATH="$GOPATH/bin:$PATH"
    fi
}

install_golang_full() {
    print_header "Installing Go Development Environment"

    # Install Go toolchain
    if ! install_golang; then
        return 1
    fi

    # Install govulncheck security scanner
    if command -v go &> /dev/null; then
        print_info "Installing govulncheck (Go vulnerability scanner)..."
        # Clear build cache to avoid stale toolchain version mismatches after upgrades
        go clean -cache
        if GOTOOLCHAIN=auto go install golang.org/x/vuln/cmd/govulncheck@latest; then
            print_success "govulncheck installed"
        else
            print_warning "Failed to install govulncheck"
        fi

        # Install Go development tools if neovim is installed
        if command -v nvim &> /dev/null; then
            print_info "Installing Go LSP and tools for Neovim..."

            # Check if Mason packages can be installed
            MASON_GO_PACKAGES="gopls delve gofumpt goimports"

            if nvim --headless "+MasonInstall $MASON_GO_PACKAGES" +qa 2>/dev/null; then
                print_success "Go development tools installed via Mason"
            else
                print_warning "Go tools may require manual installation via :Mason"
            fi
        else
            print_info "Neovim not found - skipping Go LSP tools"
            print_info "Install neovim first, then run: nvim -c 'MasonInstall gopls delve gofumpt goimports'"
        fi
    fi
}

install_nodejs() {
    print_header "Installing Node.js"

    if ! command -v fnm &> /dev/null; then
        print_info "Installing fnm (Fast Node Manager)..."
        curl -fsSL https://fnm.vercel.app/install | bash
        export PATH="$HOME/.local/share/fnm:$PATH"
        print_success "fnm installed"
    else
        print_success "fnm is already installed"
    fi

    if command -v fnm &> /dev/null; then
        print_info "Installing Node.js LTS via fnm..."
        export PATH="$HOME/.local/share/fnm:$PATH"
        eval "$(fnm env --use-on-cd --shell bash)"

        fnm install --lts
        fnm use lts-latest
        fnm default lts-latest

        NODE_VERSION=$(node --version 2>/dev/null || echo "unknown")
        print_success "Node.js $NODE_VERSION installed"
    fi
}

install_playwright() {
    print_header "Installing Playwright CLI"

    # Requires npm (Node.js)
    if ! command -v npm &> /dev/null; then
        print_error "npm not found. Install Node.js first (nodejs module)."
        return 1
    fi

    if command -v playwright-cli &> /dev/null; then
        print_success "Playwright CLI is already installed"
    else
        print_info "Installing Playwright CLI globally..."
        if npm install -g @playwright/cli@latest; then
            print_success "Playwright CLI installed"
        else
            print_warning "Failed to install Playwright CLI"
            return 1
        fi
    fi

    # Install skills integration
    if command -v playwright-cli &> /dev/null; then
        print_info "Setting up Playwright CLI skills..."
        if timeout 10 playwright-cli install --skills 2>/dev/null; then
            print_success "Playwright CLI skills installed"
        else
            print_warning "Failed to install Playwright CLI skills"
        fi
    fi
}

install_tui_tools() {
    print_header "Installing TUI Tools (lazygit, yazi, zoxide)"

    # --- lazygit ---
    if command -v lazygit &> /dev/null; then
        print_success "lazygit is already installed"
    else
        print_info "Installing lazygit..."
        if [ "$OS" == "ubuntu" ]; then
            LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            if [ -z "$LAZYGIT_VERSION" ]; then
                print_error "Failed to fetch lazygit version"
            else
                ARCH=$(uname -m)
                case "$ARCH" in
                    x86_64) LG_ARCH="Linux_x86_64" ;;
                    aarch64|arm64) LG_ARCH="Linux_arm64" ;;
                    *) print_error "Unsupported architecture: $ARCH"; LG_ARCH="" ;;
                esac

                if [ -n "$LG_ARCH" ]; then
                    TMP_DIR=$(mktemp -d)
                    curl -Lo "$TMP_DIR/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_${LG_ARCH}.tar.gz"
                    tar -xzf "$TMP_DIR/lazygit.tar.gz" -C "$TMP_DIR"
                    sudo install "$TMP_DIR/lazygit" /usr/local/bin/lazygit
                    rm -rf "$TMP_DIR"
                    print_success "lazygit ${LAZYGIT_VERSION} installed"
                fi
            fi
        elif [ "$OS" == "macos" ]; then
            brew install lazygit
            print_success "lazygit installed via brew"
        fi
    fi

    # --- yazi ---
    if command -v yazi &> /dev/null; then
        print_success "yazi is already installed"
    else
        print_info "Installing yazi..."
        if [ "$OS" == "ubuntu" ]; then
            YAZI_VERSION=$(curl -s "https://api.github.com/repos/sxyazi/yazi/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            if [ -z "$YAZI_VERSION" ]; then
                print_error "Failed to fetch yazi version"
            else
                ARCH=$(uname -m)
                case "$ARCH" in
                    x86_64) YZ_ARCH="x86_64-unknown-linux-gnu" ;;
                    aarch64|arm64) YZ_ARCH="aarch64-unknown-linux-gnu" ;;
                    *) print_error "Unsupported architecture: $ARCH"; YZ_ARCH="" ;;
                esac

                if [ -n "$YZ_ARCH" ]; then
                    TMP_DIR=$(mktemp -d)
                    curl -Lo "$TMP_DIR/yazi.zip" "https://github.com/sxyazi/yazi/releases/latest/download/yazi-${YZ_ARCH}.zip"
                    unzip -q "$TMP_DIR/yazi.zip" -d "$TMP_DIR"
                    sudo install "$TMP_DIR/yazi-${YZ_ARCH}/yazi" /usr/local/bin/yazi
                    rm -rf "$TMP_DIR"
                    print_success "yazi ${YAZI_VERSION} installed"
                fi
            fi
        elif [ "$OS" == "macos" ]; then
            brew install yazi
            print_success "yazi installed via brew"
        fi
    fi

    # --- zoxide ---
    if command -v zoxide &> /dev/null; then
        print_success "zoxide is already installed"
    else
        print_info "Installing zoxide..."
        if [ "$OS" == "ubuntu" ]; then
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            print_success "zoxide installed"
        elif [ "$OS" == "macos" ]; then
            brew install zoxide
            print_success "zoxide installed via brew"
        fi
    fi

    # --- Config symlinks ---

    # lazygit config
    if [ "$OS" == "macos" ]; then
        LAZYGIT_CONFIG_DIR="$HOME/Library/Application Support/lazygit"
    else
        LAZYGIT_CONFIG_DIR="$HOME/.config/lazygit"
    fi
    mkdir -p "$LAZYGIT_CONFIG_DIR"

    if [ -f "$LAZYGIT_CONFIG_DIR/config.yml" ] && [ ! -L "$LAZYGIT_CONFIG_DIR/config.yml" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$LAZYGIT_CONFIG_DIR/config.yml" "$LAZYGIT_CONFIG_DIR/config.yml.backup.$TIMESTAMP"
    fi
    if [ -L "$LAZYGIT_CONFIG_DIR/config.yml" ]; then
        rm "$LAZYGIT_CONFIG_DIR/config.yml"
    fi
    ln -s "$DOTFILES_DIR/lazygit/config.yml" "$LAZYGIT_CONFIG_DIR/config.yml"
    print_success "lazygit config linked"

    # yazi config
    YAZI_CONFIG_DIR="$HOME/.config/yazi"
    mkdir -p "$YAZI_CONFIG_DIR"

    for yazi_file in yazi.toml keymap.toml theme.toml; do
        if [ -f "$YAZI_CONFIG_DIR/$yazi_file" ] && [ ! -L "$YAZI_CONFIG_DIR/$yazi_file" ]; then
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            mv "$YAZI_CONFIG_DIR/$yazi_file" "$YAZI_CONFIG_DIR/$yazi_file.backup.$TIMESTAMP"
        fi
        if [ -L "$YAZI_CONFIG_DIR/$yazi_file" ]; then
            rm "$YAZI_CONFIG_DIR/$yazi_file"
        fi
        if [ -f "$DOTFILES_DIR/yazi/$yazi_file" ]; then
            ln -s "$DOTFILES_DIR/yazi/$yazi_file" "$YAZI_CONFIG_DIR/$yazi_file"
        fi
    done
    print_success "yazi config linked"
}

install_zsh() {
    print_header "Installing Oh My Zsh"

    # Check if zsh is installed
    if ! command -v zsh &> /dev/null; then
        print_warning "Zsh not found. Installing base tools first..."
        install_base_tools || return 1
    fi

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed"
    else
        print_success "Oh My Zsh is already installed"
    fi

    # Set zsh as default shell
    CURRENT_SHELL=$(basename "$SHELL")
    if [ "$CURRENT_SHELL" != "zsh" ]; then
        print_info "Setting zsh as default shell..."
        ZSH_PATH=$(which zsh)
        chsh -s "$ZSH_PATH"
        print_success "Default shell set to zsh (restart required)"
    else
        print_success "zsh is already the default shell"
    fi
}

configure_tmux() {
    print_header "Configuring Tmux"

    # Check if tmux is installed
    if ! command -v tmux &> /dev/null; then
        print_warning "Tmux not found. Installing base tools first..."
        install_base_tools || return 1
    fi

    # Backup and link config
    if [ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.$TIMESTAMP"
        print_warning "Backed up existing .tmux.conf"
    fi

    if [ -L "$HOME/.tmux.conf" ]; then
        rm "$HOME/.tmux.conf"
    fi

    ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
    print_success "Tmux configuration linked"
}

install_herdr() {
    print_header "Installing Herdr"

    if command -v herdr &> /dev/null; then
        print_success "Herdr is already installed"
        return 0
    fi

    if ! command -v curl &> /dev/null; then
        print_error "curl not found. Install base tools first."
        return 1
    fi

    print_info "Installing Herdr via official installer..."
    curl -fsSL https://herdr.dev/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v herdr &> /dev/null; then
        print_error "Herdr install failed: herdr not found on PATH"
        print_info "Ensure ~/.local/bin is on PATH, then re-run the herdr module"
        return 1
    fi

    print_success "Herdr installed"
}

configure_herdr() {
    print_header "Configuring Herdr"

    if [ ! -f "$DOTFILES_DIR/herdr/config.toml" ]; then
        print_error "Herdr config source not found: $DOTFILES_DIR/herdr/config.toml"
        return 1
    fi

    replace_symlink "$DOTFILES_DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml"
    print_success "Herdr configuration linked"
}

shell_single_quote() {
    printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\"'\"'/g")"
}

herdr_hook_command() {
    local hook_path="$1"
    local action="${2:-}"
    local command

    command="bash $(shell_single_quote "$hook_path")"
    if [ -n "$action" ]; then
        command="$command $action"
    fi
    printf '%s\n' "$command"
}

portable_claude_herdr_hook_command() {
    printf '%s\n' 'bash "$HOME/.claude/hooks/herdr-agent-state.sh" session'
}

ensure_json_object_file() {
    local path="$1"

    if [ ! -f "$path" ]; then
        printf '{}\n' > "$path"
        return 0
    fi

    if ! jq -e 'type == "object"' "$path" >/dev/null; then
        print_error "Expected JSON object in $path"
        return 1
    fi
}

absolute_path() {
    local path="$1"
    local dir

    dir="$(cd "$(dirname "$path")" && pwd)" || return 1
    printf '%s/%s\n' "$dir" "$(basename "$path")"
}

json_update_path() {
    local path="$1"
    local target
    local target_dir

    if [ ! -L "$path" ]; then
        printf '%s\n' "$path"
        return 0
    fi

    target="$(readlink "$path")" || return 1
    case "$target" in
        /*)
            printf '%s\n' "$target"
            ;;
        *)
            target_dir="$(cd "$(dirname "$path")" && cd "$(dirname "$target")" && pwd)" || return 1
            printf '%s/%s\n' "$target_dir" "$(basename "$target")"
            ;;
    esac
}

is_dotfiles_managed_claude_settings() {
    local settings_path="$1"
    local update_path
    local managed_path

    [ -L "$settings_path" ] || return 1
    update_path="$(json_update_path "$settings_path")" || return 1
    managed_path="$(absolute_path "$DOTFILES_DIR/claude/settings.json")" || return 1
    [ "$update_path" = "$managed_path" ]
}

prepare_claude_agent_settings() {
    local settings="$HOME/.claude/settings.json"
    local migrated_settings

    if ! is_dotfiles_managed_claude_settings "$settings"; then
        return 0
    fi
    if [ -f "$settings" ]; then
        migrated_settings="$HOME/.claude/.settings.json.migrate.$$"
        cp "$settings" "$migrated_settings" || return 1
        rm "$settings" || return 1
        mv "$migrated_settings" "$settings" || return 1
    else
        rm "$settings"
    fi
}

has_nested_session_hook() {
    local settings_path="$1"
    local command="$2"
    local matcher="${3:-}"

    if [ -n "$matcher" ]; then
        jq -e --arg command "$command" --arg matcher "$matcher" '
            any(.hooks.SessionStart[]?; .matcher == $matcher and any(.hooks[]?; .type == "command" and .command == $command))
        ' "$settings_path" >/dev/null
    else
        jq -e --arg command "$command" '
            any(.hooks.SessionStart[]?; any(.hooks[]?; .type == "command" and .command == $command))
        ' "$settings_path" >/dev/null
    fi
}

jq_update_file() {
    local path="$1"
    shift
    local update_path
    local tmp

    update_path="$(json_update_path "$path")" || return 1
    tmp="$(mktemp "$update_path.tmp.XXXXXX")" || return 1
    if jq "$@" "$path" > "$tmp"; then
        mv "$tmp" "$update_path"
    else
        rm -f "$tmp"
        return 1
    fi
}

ensure_claude_statusline_setting() {
    local settings="$HOME/.claude/settings.json"

    ensure_json_object_file "$settings" || return 1
    jq_update_file "$settings" '
        .statusLine = {
            type: "command",
            command: "~/.claude/statusline.sh"
        }
    '
}

add_nested_session_hook() {
    local settings_path="$1"
    local command="$2"
    local matcher="${3:-}"

    if [ -n "$matcher" ]; then
        jq_update_file "$settings_path" --arg command "$command" --arg matcher "$matcher" '
            .hooks = (.hooks // {}) |
            .hooks.SessionStart = (.hooks.SessionStart // []) |
            if any(.hooks.SessionStart[]?; any(.hooks[]?; .type == "command" and .command == $command)) then
                .
            else
                .hooks.SessionStart += [{
                    matcher: $matcher,
                    hooks: [{ type: "command", command: $command, timeout: 10 }]
                }]
            end
        '
    else
        jq_update_file "$settings_path" --arg command "$command" '
            .hooks = (.hooks // {}) |
            .hooks.SessionStart = (.hooks.SessionStart // []) |
            if any(.hooks.SessionStart[]?; any(.hooks[]?; .type == "command" and .command == $command)) then
                .
            else
                .hooks.SessionStart += [{
                    hooks: [{ type: "command", command: $command, timeout: 10 }]
                }]
            end
        '
    fi
}

add_direct_session_hook() {
    local settings_path="$1"
    local command="$2"

    jq_update_file "$settings_path" --arg command "$command" '
        .hooks = (.hooks // {}) |
        .hooks.SessionStart = (.hooks.SessionStart // []) |
        if any(.hooks.SessionStart[]?; (.bash == $command) or (.command == $command) or (.powershell == $command)) then
            .
        else
            .hooks.SessionStart += [{
                type: "command",
                bash: $command,
                timeoutSec: 10
            }]
        end
    '
}

ensure_codex_hooks_feature() {
    local config_path="$1"
    local tmp

    if [ ! -f "$config_path" ]; then
        printf '[features]\nhooks = true\n' > "$config_path"
        return 0
    fi

    tmp="$(mktemp "$config_path.tmp.XXXXXX")" || return 1
    awk '
        BEGIN { in_features = 0; saw_features = 0; saw_hooks = 0 }
        /^[[:space:]]*codex_hooks[[:space:]]*=/ { next }
        /^\[[^]]+\][[:space:]]*$/ {
            if (in_features && !saw_hooks) {
                print "hooks = true"
            }
            in_features = 0
        }
        /^\[features\][[:space:]]*$/ {
            saw_features = 1
            in_features = 1
            saw_hooks = 0
        }
        in_features && /^[[:space:]]*hooks[[:space:]]*=/ {
            print "hooks = true"
            saw_hooks = 1
            next
        }
        { print }
        END {
            if (in_features && !saw_hooks) {
                print "hooks = true"
            }
            if (!saw_features) {
                print ""
                print "[features]"
                print "hooks = true"
            }
        }
    ' "$config_path" > "$tmp" && mv "$tmp" "$config_path" || {
        rm -f "$tmp"
        return 1
    }
}

configure_herdr_integrations() {
    print_header "Configuring Herdr Integrations"

    if ! command -v jq &> /dev/null; then
        print_error "jq not found. Install base tools first."
        return 1
    fi

    local configured=0

    if [ -d "$HOME/.claude" ]; then
        local claude_hook="$HOME/.claude/hooks/herdr-agent-state.sh"
        mkdir -p "$HOME/.claude/hooks"
        replace_symlink "$DOTFILES_DIR/herdr/integrations/claude/herdr-agent-state.sh" "$claude_hook"
        local claude_settings_were_managed=0
        if is_dotfiles_managed_claude_settings "$HOME/.claude/settings.json"; then
            claude_settings_were_managed=1
        fi
        prepare_claude_agent_settings || return 1
        ensure_json_object_file "$HOME/.claude/settings.json" || return 1
        if [ "$claude_settings_were_managed" -eq 1 ]; then
            add_nested_session_hook "$HOME/.claude/settings.json" "$(portable_claude_herdr_hook_command)" "*" || return 1
        elif ! has_nested_session_hook "$HOME/.claude/settings.json" "$(portable_claude_herdr_hook_command)" "*"; then
            add_nested_session_hook "$HOME/.claude/settings.json" "$(herdr_hook_command "$claude_hook" session)" "*" || return 1
        fi
        print_success "Claude Herdr integration configured"
        configured=$((configured + 1))
    else
        print_info "Skipping Claude Herdr integration; ~/.claude not found"
    fi

    if [ -d "$HOME/.codex" ]; then
        local codex_hook="$HOME/.codex/herdr-agent-state.sh"
        replace_symlink "$DOTFILES_DIR/herdr/integrations/codex/herdr-agent-state.sh" "$codex_hook"
        ensure_json_object_file "$HOME/.codex/hooks.json" || return 1
        add_nested_session_hook "$HOME/.codex/hooks.json" "$(herdr_hook_command "$codex_hook" session)" || return 1
        ensure_codex_hooks_feature "$HOME/.codex/config.toml" || return 1
        print_success "Codex Herdr integration configured"
        configured=$((configured + 1))
    else
        print_info "Skipping Codex Herdr integration; ~/.codex not found"
    fi

    if [ -d "$HOME/.config/copilot" ]; then
        local copilot_hook="$HOME/.config/copilot/hooks/herdr-agent-state.sh"
        mkdir -p "$HOME/.config/copilot/hooks"
        replace_symlink "$DOTFILES_DIR/herdr/integrations/copilot/herdr-agent-state.sh" "$copilot_hook"
        ensure_json_object_file "$HOME/.config/copilot/settings.json" || return 1
        add_direct_session_hook "$HOME/.config/copilot/settings.json" "$(herdr_hook_command "$copilot_hook")" || return 1
        print_success "Copilot Herdr integration configured"
        configured=$((configured + 1))
    else
        print_info "Skipping Copilot Herdr integration; ~/.config/copilot not found"
    fi

    if [ -d "$HOME/.pi" ]; then
        deploy_pi_config || return 1
        print_success "Pi Herdr integration deployed through Pi agent config"
        configured=$((configured + 1))
    else
        print_info "Skipping Pi Herdr integration; ~/.pi not found"
    fi

    if [ "$configured" -eq 0 ]; then
        print_info "No existing managed agent configs found for Herdr integrations"
    fi
}

configure_zsh() {
    print_header "Configuring Zsh"

    # Check if zsh is installed
    if ! command -v zsh &> /dev/null; then
        print_warning "Zsh not found. Installing base tools first..."
        install_base_tools || return 1
    fi

    # Add custom config to .zshrc
    if ! grep -q "source ~/dotfiles/zsh/.zshrc.custom" "$HOME/.zshrc" 2>/dev/null; then
        print_info "Adding custom configuration to .zshrc..."
        echo "" >> "$HOME/.zshrc"
        echo "# Source custom dotfiles configuration" >> "$HOME/.zshrc"
        echo "if [ -f ~/dotfiles/zsh/.zshrc.custom ]; then" >> "$HOME/.zshrc"
        echo "    source ~/dotfiles/zsh/.zshrc.custom" >> "$HOME/.zshrc"
        echo "fi" >> "$HOME/.zshrc"
        print_success "Custom zsh configuration added"
    else
        print_success "Custom zsh configuration already sourced"
    fi
}

install_claude() {
    print_header "Installing Claude Code"

    local claude_settings="$HOME/.claude/settings.json"
    local preserved_settings=""

    prepare_claude_agent_settings || return 1

    if [ -f "$claude_settings" ] && [ ! -L "$claude_settings" ]; then
        preserved_settings="$HOME/.claude/.settings.json.install.$$"
        mv "$claude_settings" "$preserved_settings" || return 1
    fi

    print_info "Installing/updating Claude Code CLI to latest..."
    if ! curl -fsSL https://claude.ai/install.sh | bash -s latest; then
        if [ -n "$preserved_settings" ]; then
            rm -f "$claude_settings"
            mv "$preserved_settings" "$claude_settings"
        fi
        return 1
    fi
    export PATH="$HOME/.local/bin:$PATH"

    if [ -n "$preserved_settings" ]; then
        rm -f "$claude_settings"
        mv "$preserved_settings" "$claude_settings" || return 1
    fi

    if [ ! -x "$HOME/.local/bin/claude" ]; then
        print_error "Claude Code CLI install failed: ~/.local/bin/claude not found"
        return 1
    fi

    if command -v claude &> /dev/null && [ "$(command -v claude)" != "$HOME/.local/bin/claude" ]; then
        print_warning "Another claude binary is earlier in PATH: $(command -v claude)"
    fi

    print_success "Claude Code CLI installed/updated at ~/.local/bin/claude"

    mkdir -p "$HOME/.claude"

    # Link commands
    if [ -L "$HOME/.claude/commands" ]; then
        rm "$HOME/.claude/commands"
    elif [ -d "$HOME/.claude/commands" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.claude/commands" "$HOME/.claude/commands.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/claude/commands" "$HOME/.claude/commands"

    # Link agents
    if [ -L "$HOME/.claude/agents" ]; then
        rm "$HOME/.claude/agents"
    elif [ -d "$HOME/.claude/agents" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.claude/agents" "$HOME/.claude/agents.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"

    # Link skills
    if [ -L "$HOME/.claude/skills" ]; then
        rm "$HOME/.claude/skills"
    elif [ -d "$HOME/.claude/skills" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.claude/skills" "$HOME/.claude/skills.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/shared/skills" "$HOME/.claude/skills"

    # Link statusline
    if [ -L "$HOME/.claude/statusline.sh" ]; then
        rm "$HOME/.claude/statusline.sh"
    elif [ -f "$HOME/.claude/statusline.sh" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.claude/statusline.sh" "$HOME/.claude/statusline.sh.backup.$TIMESTAMP"
    fi
    if [ -f "$DOTFILES_DIR/claude/statusline.sh" ]; then
        ln -s "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
        ensure_claude_statusline_setting || return 1
    fi

    print_success "Claude Code configured"
    print_info "Run 'claude auth login' to authenticate"

    # Remove legacy Playwright MCP server if present
    if claude mcp list 2>/dev/null | grep -q "playwright"; then
        print_info "Removing legacy Playwright MCP server..."
        claude mcp remove playwright 2>/dev/null || true
        print_success "Playwright MCP server removed"
    fi
}

install_pi() {
    print_header "Installing Pi Coding Agent"

    # Pi is distributed as an npm package.
    # Install to ~/.local so it is shared across fnm Node versions.
    if ! command -v npm &> /dev/null; then
        print_warning "npm not found. Installing Node.js first..."
        install_nodejs || return 1
    fi

    mkdir -p "$HOME/.local/bin"

    # Clean up old deprecated package and binary to allow rename from @mariozechner -> @earendil-works
    if npm ls --prefix "$HOME/.local" -g @mariozechner/pi-coding-agent &>/dev/null 2>&1; then
        print_info "Removing deprecated @mariozechner/pi-coding-agent..."
        npm uninstall -g --prefix "$HOME/.local" @mariozechner/pi-coding-agent || true
    fi

    print_info "Installing/updating Pi coding agent via npm into ~/.local..."
    npm install -g --prefix "$HOME/.local" @earendil-works/pi-coding-agent@latest

    if [ ! -x "$HOME/.local/bin/pi" ]; then
        print_error "Pi coding agent install failed: ~/.local/bin/pi not found"
        return 1
    fi

    if [ ! -L "$HOME/.local/bin/pi" ] || [ "$(readlink "$HOME/.local/bin/pi" 2>/dev/null || true)" != "$DOTFILES_DIR/pi/pi.sh" ]; then
        mv "$HOME/.local/bin/pi" "$HOME/.local/bin/pi-bin"
    fi

    if command -v pi &> /dev/null && [ "$(command -v pi)" != "$HOME/.local/bin/pi" ]; then
        print_warning "Another pi binary is earlier in PATH: $(command -v pi)"
        print_info "Ensure ~/.local/bin is first in PATH to use the shared Pi install"
    fi
    print_success "Pi coding agent installed/updated at ~/.local/bin/pi-bin"

    deploy_pi_config || return 1
    deploy_pi_wrappers

    print_success "Pi coding agent configured"
    print_info "Run 'pi' to start (first launch prompts for authentication)"
}

backup_existing_path() {
    local target="$1"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    mv "$target" "$target.backup.$timestamp"
}

replace_symlink() {
    local source="$1"
    local target="$2"

    mkdir -p "$(dirname "$target")"
    if [ -L "$target" ]; then
        if [ "$(readlink "$target")" = "$source" ]; then
            return 0
        fi
        rm "$target"
    elif [ -e "$target" ]; then
        backup_existing_path "$target"
    fi
    ln -s "$source" "$target"
}

prune_pi_extension_symlinks() {
    local source_extensions="$1"
    local runtime_extensions="$2"
    local allowed="$3"
    local entry name

    [ -d "$runtime_extensions" ] || return 0

    for entry in "$runtime_extensions"/*; do
        [ -e "$entry" ] || [ -L "$entry" ] || continue
        name="$(basename "$entry")"
        if printf '%s\n' $allowed | grep -qx "$name" && { [ -e "$source_extensions/$name" ] || [ -L "$source_extensions/$name" ]; }; then
            continue
        fi
        if [ -L "$entry" ]; then
            rm "$entry"
        else
            print_error "Unmanaged Pi runtime extension exists: $entry"
            return 1
        fi
    done
}

deploy_pi_wrappers() {
    local bin_dir="$HOME/.local/bin"
    local wrapper target
    mkdir -p "$bin_dir"

    replace_symlink "$DOTFILES_DIR/pi/pi.sh" "$bin_dir/pi"
    replace_symlink "$DOTFILES_DIR/pi/pis.sh" "$bin_dir/pis"

    if [ -L "$bin_dir/pim" ]; then
        rm "$bin_dir/pim"
    fi
    for wrapper in "$bin_dir"/pi-* "$bin_dir"/pis-*; do
        [ -L "$wrapper" ] || continue
        target="$(readlink "$wrapper")"
        if [ "$target" = "$DOTFILES_DIR/pi/pi.sh" ] || [ "$target" = "$DOTFILES_DIR/pi/pis.sh" ]; then
            rm "$wrapper"
        fi
    done
}

prepare_pi_agent_settings() {
    local agent="$HOME/.pi/agent"
    local settings="$agent/settings.json"
    local migrated_settings

    mkdir -p "$agent"
    if [ -L "$settings" ]; then
        if [ -f "$settings" ]; then
            migrated_settings="$agent/.settings.json.migrate.$$"
            cp "$settings" "$migrated_settings" || return 1
            rm "$settings" || return 1
            mv "$migrated_settings" "$settings" || return 1
        else
            rm "$settings"
        fi
    fi
    if [ ! -f "$settings" ]; then
        printf '{}\n' > "$settings"
    fi
}

prepare_pi_agent_auth() {
    local agent="$HOME/.pi/agent"

    mkdir -p "$agent"
    if [ -L "$agent/auth.json" ]; then
        rm "$agent/auth.json"
    fi
    if [ -f "$agent/auth.json" ]; then
        return 0
    fi
    if [ -f "$HOME/.pi/auth.json" ]; then
        cp "$HOME/.pi/auth.json" "$agent/auth.json"
    else
        printf '{}\n' > "$agent/auth.json"
    fi
}

deploy_pi_config() {
    local agent="$HOME/.pi/agent"
    local source_extensions="$DOTFILES_DIR/pi/extensions"
    local enabled_extensions="herdr-agent-state inherit-last-model web-search"
    local extension

    mkdir -p "$agent/extensions" "$agent/sessions"
    prepare_pi_agent_settings
    prepare_pi_agent_auth

    replace_symlink "$DOTFILES_DIR/pi/models.json" "$agent/models.json"
    replace_symlink "$DOTFILES_DIR/pi/skills" "$agent/skills"

    prune_pi_extension_symlinks "$source_extensions" "$agent/extensions" "$enabled_extensions" || return 1
    for extension in $enabled_extensions; do
        if [ ! -e "$source_extensions/$extension" ] && [ ! -L "$source_extensions/$extension" ]; then
            print_error "Pi extension missing: $source_extensions/$extension"
            return 1
        fi
        replace_symlink "$source_extensions/$extension" "$agent/extensions/$extension"
    done
}

install_pi_sandbox() {
    print_header "Installing Pi Sandbox (Docker)"

    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Install Docker first."
        return 1
    fi

    # Build the Docker image (pin Pi version from npm so the image label is accurate)
    print_info "Resolving latest Pi version for sandbox image..."
    PI_SANDBOX_VER=$(npm view @earendil-works/pi-coding-agent version 2>/dev/null || echo "latest")
    SANDBOX_BASE_IMAGE="dotfiles-dev-base:$(id -u)-$(id -g)"
    print_info "Ensuring shared sandbox base image (${SANDBOX_BASE_IMAGE})..."
    if ! docker build \
        -f "$DOTFILES_DIR/docker/dev-base.Dockerfile" \
        --build-arg HOST_USER="$(whoami)" \
        --build-arg HOST_UID="$(id -u)" \
        --build-arg HOST_GID="$(id -g)" \
        -t "$SANDBOX_BASE_IMAGE" "$DOTFILES_DIR"; then
        print_error "Failed to build shared sandbox base image"
        return 1
    fi
    print_info "Building Pi sandbox Docker image (Pi @${PI_SANDBOX_VER})..."
    if docker build \
        --build-arg BASE_IMAGE="$SANDBOX_BASE_IMAGE" \
        --build-arg PI_VERSION="$PI_SANDBOX_VER" \
        --build-arg HOST_USER="$(whoami)" \
        --build-arg HOST_GID="$(id -g)" \
        -t "pis:latest" "$DOTFILES_DIR/pi/"; then
        print_success "Pi sandbox Docker image built (Pi @${PI_SANDBOX_VER})"
    else
        print_error "Failed to build Pi sandbox Docker image"
        return 1
    fi

    # Symlink pis script
    mkdir -p "$HOME/.local/bin"
    if [ -L "$HOME/.local/bin/pis" ]; then
        rm "$HOME/.local/bin/pis"
    elif [ -f "$HOME/.local/bin/pis" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.local/bin/pis" "$HOME/.local/bin/pis.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/pi/pis.sh" "$HOME/.local/bin/pis"

    print_success "Pi sandbox configured (run 'pis' to launch)"
}

link_codex_shared_skills() {
    "$DOTFILES_DIR/codex/sync-skills.sh" || print_warning "Failed to sync Codex shared skills"
}

install_codex() {
    print_header "Installing Codex CLI"

    # Codex is distributed as an npm package.
    # Install to ~/.local so it is shared across fnm Node versions.
    if ! command -v npm &> /dev/null; then
        print_warning "npm not found. Installing Node.js first..."
        install_nodejs || return 1
    fi

    mkdir -p "$HOME/.local/bin"
    print_info "Installing/updating Codex CLI via npm into ~/.local..."
    npm install -g --prefix "$HOME/.local" @openai/codex@latest

    if [ ! -x "$HOME/.local/bin/codex" ]; then
        print_error "Codex CLI install failed: ~/.local/bin/codex not found"
        return 1
    fi

    if command -v codex &> /dev/null && [ "$(command -v codex)" != "$HOME/.local/bin/codex" ]; then
        print_warning "Another codex binary is earlier in PATH: $(command -v codex)"
        print_info "Ensure ~/.local/bin is first in PATH to use the shared Codex install"
    fi
    print_success "Codex CLI installed/updated at ~/.local/bin/codex"

    mkdir -p "$HOME/.codex"
    mkdir -p "$HOME/.agents"

    # Seed config.toml (copy, not symlink).
    # Codex writes machine/project-specific values here, which should stay local.
    if [ -f "$DOTFILES_DIR/codex/config.toml" ]; then
        if [ -L "$HOME/.codex/config.toml" ]; then
            print_info "Converting ~/.codex/config.toml symlink to local file..."
            rm "$HOME/.codex/config.toml"
            cp "$DOTFILES_DIR/codex/config.toml" "$HOME/.codex/config.toml"
            print_success "Created local ~/.codex/config.toml from dotfiles template"
        elif [ "$CODEX_CONFIG_TEMPLATE_MODE" == "overwrite" ] && [ -f "$HOME/.codex/config.toml" ]; then
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            mv "$HOME/.codex/config.toml" "$HOME/.codex/config.toml.backup.$TIMESTAMP"
            cp "$DOTFILES_DIR/codex/config.toml" "$HOME/.codex/config.toml"
            print_success "Overwrote ~/.codex/config.toml from template (backup: config.toml.backup.$TIMESTAMP)"
        elif [ ! -f "$HOME/.codex/config.toml" ]; then
            cp "$DOTFILES_DIR/codex/config.toml" "$HOME/.codex/config.toml"
            print_success "Created ~/.codex/config.toml from dotfiles template"
        else
            print_success "Keeping existing ~/.codex/config.toml (local runtime config)"
        fi
    fi

    # Link agents directory
    if [ -L "$HOME/.codex/agents" ]; then
        rm "$HOME/.codex/agents"
    elif [ -d "$HOME/.codex/agents" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.codex/agents" "$HOME/.codex/agents.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/codex/agents" "$HOME/.codex/agents"

    # Link global AGENTS.md (optional)
    if [ -f "$DOTFILES_DIR/codex/AGENTS.md" ]; then
        if [ -f "$HOME/.codex/AGENTS.md" ] && [ ! -L "$HOME/.codex/AGENTS.md" ]; then
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            mv "$HOME/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md.backup.$TIMESTAMP"
        fi
        if [ -L "$HOME/.codex/AGENTS.md" ]; then
            rm "$HOME/.codex/AGENTS.md"
        fi
        ln -s "$DOTFILES_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
    fi

    # Link user skills directory for cross-agent installers that still use ~/.agents.
    if [ -L "$HOME/.agents/skills" ]; then
        rm "$HOME/.agents/skills"
    elif [ -e "$HOME/.agents/skills" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.agents/skills" "$HOME/.agents/skills.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/shared/skills" "$HOME/.agents/skills"

    # Codex loads skills from ~/.codex/skills. Keep Codex's built-in .system
    # directory intact and expose each shared skill as an individual symlink.
    link_codex_shared_skills

    print_success "Codex configured"
    print_info "Run 'codex login' to authenticate"
}

install_codex_sandbox() {
    print_header "Installing Codex Sandbox (Docker)"

    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Install Docker first."
        return 1
    fi

    if ! command -v npm &> /dev/null; then
        print_warning "npm not found. Installing Node.js first..."
        install_nodejs || return 1
    fi

    print_info "Resolving latest Codex version for sandbox image..."
    CODEX_SANDBOX_VER=$(npm view @openai/codex version 2>/dev/null || echo "latest")
    SANDBOX_BASE_IMAGE="dotfiles-dev-base:$(id -u)-$(id -g)"
    print_info "Ensuring shared sandbox base image (${SANDBOX_BASE_IMAGE})..."
    if ! docker build \
        -f "$DOTFILES_DIR/docker/dev-base.Dockerfile" \
        --build-arg HOST_USER="$(whoami)" \
        --build-arg HOST_UID="$(id -u)" \
        --build-arg HOST_GID="$(id -g)" \
        -t "$SANDBOX_BASE_IMAGE" "$DOTFILES_DIR"; then
        print_error "Failed to build shared sandbox base image"
        return 1
    fi
    print_info "Building Codex sandbox Docker image (Codex @${CODEX_SANDBOX_VER})..."
    if docker build \
        --build-arg BASE_IMAGE="$SANDBOX_BASE_IMAGE" \
        --build-arg CODEX_VERSION="$CODEX_SANDBOX_VER" \
        --build-arg HOST_USER="$(whoami)" \
        --build-arg HOST_GID="$(id -g)" \
        -t "cods:latest" "$DOTFILES_DIR/codex/"; then
        print_success "Codex sandbox Docker image built (Codex @${CODEX_SANDBOX_VER})"
    else
        print_error "Failed to build Codex sandbox Docker image"
        return 1
    fi

    mkdir -p "$HOME/.local/bin"
    if [ -L "$HOME/.local/bin/cods" ]; then
        rm "$HOME/.local/bin/cods"
    elif [ -f "$HOME/.local/bin/cods" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.local/bin/cods" "$HOME/.local/bin/cods.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/codex/cods.sh" "$HOME/.local/bin/cods"

    print_success "Codex sandbox configured (run 'cods' to launch)"
}

install_copilot() {
    print_header "Installing GitHub Copilot CLI"

    # GitHub Copilot CLI is installed via official curl installer.
    # Binary lands in ~/.local/bin/copilot (non-root default).
    if ! command -v curl &> /dev/null; then
        print_error "curl not found. Install base tools first."
        return 1
    fi

    mkdir -p "$HOME/.local/bin"
    print_info "Installing/updating GitHub Copilot CLI via curl installer..."
    curl -fsSL https://gh.io/copilot-install | bash

    if [ ! -x "$HOME/.local/bin/copilot" ]; then
        print_error "Copilot CLI install failed: ~/.local/bin/copilot not found"
        return 1
    fi

    print_success "GitHub Copilot CLI installed at ~/.local/bin/copilot"

    mkdir -p "$HOME/.config/copilot"

    # Link commands directory
    if [ -L "$HOME/.config/copilot/commands" ]; then
        rm "$HOME/.config/copilot/commands"
    elif [ -d "$HOME/.config/copilot/commands" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.config/copilot/commands" "$HOME/.config/copilot/commands.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/copilot/commands" "$HOME/.config/copilot/commands"

    # Link agents directory
    if [ -L "$HOME/.config/copilot/agents" ]; then
        rm "$HOME/.config/copilot/agents"
    elif [ -d "$HOME/.config/copilot/agents" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.config/copilot/agents" "$HOME/.config/copilot/agents.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/copilot/agents" "$HOME/.config/copilot/agents"

    # Link skills directory
    if [ -L "$HOME/.config/copilot/skills" ]; then
        rm "$HOME/.config/copilot/skills"
    elif [ -d "$HOME/.config/copilot/skills" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.config/copilot/skills" "$HOME/.config/copilot/skills.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/shared/skills" "$HOME/.config/copilot/skills"

    print_success "GitHub Copilot CLI configured"
    print_info "Run 'copilot login' to authenticate with GitHub"
}

# ===========================
# Editor and Runtime Modules
# ===========================
#
# These modules own the platform gate and failure reporting for the selectable
# editor/runtime surface. Their provisioning internals are added by the
# following implementation steps; until then they report an unimplemented
# module failure instead of installing a substitute.

install_python() {
    print_header "Installing Python"
    print_error "Python provisioning is not implemented yet"
    return 1
}

install_vscode() {
    print_header "Installing Visual Studio Code"

    if [ "$OS" != "macos" ]; then
        print_error "Visual Studio Code Desktop is supported on macOS only (detected: ${OS:-unknown})"
        return 1
    fi

    print_error "Visual Studio Code Desktop installation is not implemented yet"
    return 1
}

configure_vscode() {
    print_header "Configuring Visual Studio Code"

    if [ "$OS" != "macos" ]; then
        print_error "The VS Code managed configuration is supported on macOS only (detected: ${OS:-unknown})"
        return 1
    fi

    print_error "VS Code managed configuration is not implemented yet"
    return 1
}

install_code_server() {
    print_header "Installing code-server"

    if [ "$OS" != "ubuntu" ]; then
        print_error "code-server is supported on Ubuntu/Debian only (detected: ${OS:-unknown})"
        return 1
    fi

    print_error "code-server provisioning is not implemented yet"
    return 1
}

# ===========================
# code-server Bind Value
# ===========================

# Split an `address:port` bind value into "host port" on stdout.
# Accepts a hostname/IPv4 address, or a bracketed IPv6 address, plus a port in
# 1..65535. Returns non-zero without output for any other shape.
split_code_server_bind() {
    local bind="$1"
    local host
    local port

    if [[ "$bind" == \[* ]]; then
        [[ "$bind" =~ ^\[([0-9A-Fa-f:.%]+)\]:([0-9]{1,5})$ ]] || return 1
    else
        [[ "$bind" =~ ^([A-Za-z0-9._-]+):([0-9]{1,5})$ ]] || return 1
    fi

    host="${BASH_REMATCH[1]}"
    port="${BASH_REMATCH[2]}"

    if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi

    printf '%s %s\n' "$host" "$port"
}

# ===========================
# Installation Profiles
# ===========================

# Expand a standard installation profile into its module list.
# Must run after detect_os: macOS-only editor modules are added here rather
# than selected and skipped later. Standard profiles never include code_server.
expand_profile() {
    local profile="$1"
    local common=()
    local module

    case "$profile" in
        full)
            common=(base_tools neovim nvim_config tmux_config herdr herdr_config zsh_ohmyzsh zsh_config python golang_full nodejs tui_tools codex codex_sandbox claude playwright pi pi_sandbox copilot herdr_integrations)
            ;;
        minimal)
            common=(base_tools neovim nvim_config tmux_config herdr herdr_config herdr_integrations)
            ;;
        work)
            common=(base_tools neovim nvim_config tmux_config herdr herdr_config python tui_tools copilot herdr_integrations)
            ;;
        *)
            print_error "Unknown profile: $profile" >&2
            return 1
            ;;
    esac

    for module in "${common[@]}"; do
        printf '%s\n' "$module"
    done

    # macOS-only additions; other platforms omit them rather than selecting
    # and skipping them later.
    if [ "$OS" == "macos" ]; then
        case "$profile" in
            full|work)
                printf '%s\n' vscode vscode_config
                ;;
        esac
    fi
}

# ===========================
# Dependency Resolution
# ===========================

resolve_dependencies() {
    local modules=("$@")
    local resolved=()

    # Add each module and its dependencies
    for module in "${modules[@]}"; do
        case "$module" in
            "nvim_config")
                # Neovim config needs git and neovim
                if ! command -v git &> /dev/null; then
                    print_warning "Adding git (required by neovim config)" >&2
                    resolved+=("base_tools")
                fi
                if ! command -v nvim &> /dev/null; then
                    print_warning "Adding neovim (required by neovim config)" >&2
                    resolved+=("neovim")
                fi
                resolved+=("nvim_config")
                ;;
            "zsh_ohmyzsh")
                # Oh My Zsh needs zsh and git
                if ! command -v zsh &> /dev/null; then
                    print_warning "Adding zsh (required by Oh My Zsh)" >&2
                    resolved+=("base_tools")
                fi
                if ! command -v git &> /dev/null; then
                    print_warning "Adding git (required by Oh My Zsh)" >&2
                    resolved+=("base_tools")
                fi
                resolved+=("zsh_ohmyzsh")
                ;;
            "tmux_config")
                # Tmux config needs tmux
                if ! command -v tmux &> /dev/null; then
                    print_warning "Adding tmux (required by tmux config)" >&2
                    resolved+=("base_tools")
                fi
                resolved+=("tmux_config")
                ;;
            "herdr")
                # Herdr direct installer needs curl.
                if ! command -v curl &> /dev/null; then
                    print_warning "Adding curl (required by Herdr)" >&2
                    resolved+=("base_tools")
                fi
                resolved+=("herdr")
                ;;
            "herdr_config")
                if ! command -v herdr &> /dev/null; then
                    print_warning "Adding Herdr (required by Herdr config)" >&2
                    if ! command -v curl &> /dev/null; then
                        print_warning "Adding curl (required by Herdr)" >&2
                        resolved+=("base_tools")
                    fi
                    resolved+=("herdr")
                fi
                resolved+=("herdr_config")
                ;;
            "herdr_integrations")
                if ! command -v jq &> /dev/null; then
                    print_warning "Adding jq (required by Herdr integrations)" >&2
                    resolved+=("base_tools")
                fi
                if ! command -v herdr &> /dev/null; then
                    print_warning "Adding Herdr (required by Herdr integrations)" >&2
                    if ! command -v curl &> /dev/null; then
                        print_warning "Adding curl (required by Herdr)" >&2
                        resolved+=("base_tools")
                    fi
                    resolved+=("herdr")
                fi
                resolved+=("herdr_integrations")
                ;;
            "zsh_config")
                # Zsh config needs zsh
                if ! command -v zsh &> /dev/null; then
                    print_warning "Adding zsh (required by zsh config)" >&2
                    resolved+=("base_tools")
                fi
                resolved+=("zsh_config")
                ;;
            "claude")
                # Claude Code needs curl for installation and jq for local settings updates.
                if ! command -v curl &> /dev/null || ! command -v jq &> /dev/null; then
                    print_warning "Adding base tools (required by Claude Code)" >&2
                    resolved+=("base_tools")
                fi
                resolved+=("claude")
                ;;
            "pi")
                # Pi coding agent uses npm
                if ! command -v npm &> /dev/null; then
                    print_warning "Adding Node.js (required by Pi coding agent)" >&2
                    resolved+=("nodejs")
                fi
                resolved+=("pi")
                ;;
            "pi_sandbox")
                # Pi sandbox needs Docker (not installed by this script) and pi
                if ! command -v docker &> /dev/null; then
                    print_warning "Docker required for Pi sandbox (install Docker separately)" >&2
                fi
                resolved+=("pi_sandbox")
                ;;
            "codex_sandbox")
                # Codex sandbox needs Docker (not installed by this script), npm, and Codex config.
                if ! command -v docker &> /dev/null; then
                    print_warning "Docker required for Codex sandbox (install Docker separately)" >&2
                fi
                if ! command -v npm &> /dev/null; then
                    print_warning "Adding Node.js (required by Codex sandbox)" >&2
                    resolved+=("nodejs")
                fi
                resolved+=("codex")
                resolved+=("codex_sandbox")
                ;;
            "codex")
                # Codex CLI install uses npm
                if ! command -v npm &> /dev/null; then
                    print_warning "Adding Node.js (required by Codex CLI)" >&2
                    resolved+=("nodejs")
                fi
                resolved+=("codex")
                ;;
            "copilot")
                # Copilot CLI uses curl installer
                if ! command -v curl &> /dev/null; then
                    print_warning "Adding curl (required by Copilot CLI)" >&2
                    resolved+=("base_tools")
                fi
                resolved+=("copilot")
                ;;
            "vscode_config")
                # The managed desktop layer needs the official editor CLI, which
                # only exists on the supported desktop platform.
                if [ "$OS" == "macos" ] && ! command -v code &> /dev/null; then
                    print_warning "Adding Visual Studio Code (required by VS Code configuration)" >&2
                    resolved+=("vscode")
                fi
                resolved+=("vscode_config")
                ;;
            "code_server")
                # The official code-server installer needs curl.
                if ! command -v curl &> /dev/null; then
                    print_warning "Adding curl (required by code-server)" >&2
                    resolved+=("base_tools")
                fi
                resolved+=("code_server")
                ;;
            "playwright")
                # Playwright CLI needs npm (Node.js)
                if ! command -v npm &> /dev/null; then
                    print_warning "Adding Node.js (required by Playwright CLI)" >&2
                    resolved+=("nodejs")
                fi
                resolved+=("playwright")
                ;;
            *)
                resolved+=("$module")
                ;;
        esac
    done

    # Remove duplicates while preserving order
    printf '%s\n' "${resolved[@]}" | awk '!seen[$0]++'
}

# ===========================
# Module Catalog
# ===========================

# Single source of module identifiers and human-readable labels, emitted as
# "name:label" lines. Indexed output keeps the menu Bash 3.2 compatible.
module_catalog() {
    cat << 'EOF'
base_tools:Base Tools (git, curl, tmux, zsh, etc.)
neovim:Neovim 0.12+
nvim_config:Neovim Configuration (kickstart + custom)
tmux_config:Tmux Configuration
herdr:Herdr Terminal Workspace Manager
herdr_config:Herdr Configuration
herdr_integrations:Herdr Agent Integrations
zsh_ohmyzsh:Zsh + Oh My Zsh
zsh_config:Zsh Custom Configuration
python:Python 3.10+ (native interpreter + venv)
golang:Go 1.24+ Toolchain (basic)
golang_full:Go Development (toolchain + LSP + tools + govulncheck)
nodejs:Node.js LTS (fnm)
codex:Codex CLI
codex_sandbox:Codex Sandbox (Docker)
claude:Claude Code CLI
pi:Pi Coding Agent
pi_sandbox:Pi Sandbox (Docker)
tui_tools:TUI Tools (lazygit, yazi, zoxide)
playwright:Playwright CLI (browser automation)
copilot:GitHub Copilot CLI
vscode:Visual Studio Code Desktop (macOS)
vscode_config:VS Code Managed Configuration (macOS)
code_server:code-server Browser Endpoint (Ubuntu/Debian)
EOF
}

# Human-readable label for one module; unknown modules fall back to their name
# so a new module can never be displayed as nothing.
module_label() {
    local key="$1"
    local line

    while IFS= read -r line; do
        if [ "${line%%:*}" == "$key" ]; then
            printf '%s\n' "${line#*:}"
            return 0
        fi
    done < <(module_catalog)

    printf '%s\n' "$key"
}

# Modules offered by the custom menu. `golang` is omitted because the menu
# offers the full Go development module instead.
custom_menu_options() {
    module_catalog | grep -v '^golang:'
}

# ===========================
# Menu System
# ===========================

show_profile_menu() {
    print_header "Dotfiles Installation"

    echo "Select installation profile:"
    echo ""
    echo "  1) Full Installation"
    echo "     Everything: Neovim, Tmux, Herdr, Zsh, Go, Node.js, AI agents"
    echo ""
    echo "  2) Minimal (editors only)"
    echo "     Neovim + config, Tmux fallback, Herdr"
    echo ""
    echo "  3) Work Profile"
    echo "     Neovim, Tmux fallback, Herdr, TUI tools, Copilot CLI"
    echo ""
    echo "  4) Custom (pick components)"
    echo "     Interactive component selection"
    echo ""
    echo "  0) Exit"
    echo ""

    read -p "Enter choice [0-4]: " choice

    case $choice in
        1)
            SELECTED_MODULES=($(expand_profile full))
            ;;
        2)
            SELECTED_MODULES=($(expand_profile minimal))
            ;;
        3)
            SELECTED_MODULES=($(expand_profile work))
            ;;
        4)
            show_custom_menu
            return
            ;;
        0)
            print_info "Installation cancelled"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            show_profile_menu
            return
            ;;
    esac
}

show_custom_menu() {
    print_header "Custom Component Selection"

    # Parallel arrays instead of associative array (bash 3.2 compat)
    local options=()
    local option_line

    while IFS= read -r option_line; do
        options+=("$option_line")
    done < <(custom_menu_options)

    local count=${#options[@]}
    local toggle_num=$((count + 1))
    local done_num=$((count + 2))

    # Indexed selection state (0 = off, 1 = on)
    local selected=()
    for ((i=0; i<count; i++)); do
        selected[$i]=0
    done

    while true; do
        clear
        print_header "Select Components"

        echo "Current selections:"
        for ((i=0; i<count; i++)); do
            local desc="${options[$i]#*:}"
            if [ "${selected[$i]}" == "1" ]; then
                echo "  [X] $desc"
            else
                echo "  [ ] $desc"
            fi
        done

        echo ""
        echo "Options:"
        for ((i=0; i<count; i++)); do
            local desc="${options[$i]#*:}"
            echo "  $((i + 1))) $desc"
        done
        echo "  ${toggle_num}) Toggle All"
        echo "  ${done_num}) Done"
        echo ""

        read -p "Enter number to toggle (or ${done_num} when done): " choice

        if [ "$choice" == "$done_num" ]; then
            break
        elif [ "$choice" == "$toggle_num" ]; then
            # Toggle all
            local all_selected=1
            for ((i=0; i<count; i++)); do
                if [ "${selected[$i]}" == "0" ]; then
                    all_selected=0
                    break
                fi
            done
            for ((i=0; i<count; i++)); do
                if [ "$all_selected" == "1" ]; then
                    selected[$i]=0
                else
                    selected[$i]=1
                fi
            done
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
            local idx=$((choice - 1))
            if [ "${selected[$idx]}" == "1" ]; then
                selected[$idx]=0
            else
                selected[$idx]=1
            fi
        else
            print_error "Invalid choice"
            sleep 1
        fi
    done

    # Build selected modules array
    SELECTED_MODULES=()
    for ((i=0; i<count; i++)); do
        if [ "${selected[$i]}" == "1" ]; then
            local key="${options[$i]%%:*}"
            SELECTED_MODULES+=("$key")
        fi
    done
}

show_installation_summary() {
    print_header "Installation Summary"

    if [ ${#SELECTED_MODULES[@]} -eq 0 ]; then
        print_warning "No modules selected"
        return 1
    fi

    echo "The following components will be installed:"
    for module in "${SELECTED_MODULES[@]}"; do
        echo "  • $(module_label "$module")"
    done

    echo ""
    if [ ! -t 0 ]; then
        print_info "No interactive stdin detected; proceeding without confirmation"
        return 0
    fi

    read -p "Proceed with installation? (y/n) " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        return 1
    fi

    return 0
}

# ===========================
# Module Execution
# ===========================

# Run one module function, recording success or failure without halting the
# remaining modules.
run_module() {
    local module="$1"
    local module_function="$2"

    if "$module_function"; then
        COMPLETED_MODULES+=("$module")
    else
        FAILED_MODULES+=("$module")
    fi
}

execute_modules() {
    local modules=("$@")
    local run_herdr_integrations=0

    for module in "${modules[@]}"; do
        case "$module" in
            "base_tools") run_module base_tools install_base_tools ;;
            "neovim") run_module neovim install_neovim ;;
            "nvim_config") run_module nvim_config configure_neovim ;;
            "tmux_config") run_module tmux_config configure_tmux ;;
            "herdr") run_module herdr install_herdr ;;
            "herdr_config") run_module herdr_config configure_herdr ;;
            "herdr_integrations")
                # Deferred so agent configs exist before integrations deploy.
                run_herdr_integrations=1
                ;;
            "zsh_ohmyzsh") run_module zsh_ohmyzsh install_zsh ;;
            "zsh_config") run_module zsh_config configure_zsh ;;
            "python") run_module python install_python ;;
            "golang") run_module golang install_golang ;;
            "golang_full") run_module golang_full install_golang_full ;;
            "nodejs") run_module nodejs install_nodejs ;;
            "codex") run_module codex install_codex ;;
            "codex_sandbox") run_module codex_sandbox install_codex_sandbox ;;
            "claude") run_module claude install_claude ;;
            "pi") run_module pi install_pi ;;
            "pi_sandbox") run_module pi_sandbox install_pi_sandbox ;;
            "tui_tools") run_module tui_tools install_tui_tools ;;
            "playwright") run_module playwright install_playwright ;;
            "copilot") run_module copilot install_copilot ;;
            "vscode") run_module vscode install_vscode ;;
            "vscode_config") run_module vscode_config configure_vscode ;;
            "code_server") run_module code_server install_code_server ;;
            *)
                print_error "Unknown module: $module"
                FAILED_MODULES+=("$module")
                ;;
        esac
    done

    if [ "$run_herdr_integrations" -eq 1 ]; then
        run_module herdr_integrations configure_herdr_integrations
    fi
}

# ===========================
# Editor Completion Notices
# ===========================

module_completed() {
    local wanted="$1"
    local module

    # Expansion guard keeps an empty list safe on the oldest supported shell.
    for module in ${COMPLETED_MODULES[@]+"${COMPLETED_MODULES[@]}"}; do
        if [ "$module" == "$wanted" ]; then
            return 0
        fi
    done

    return 1
}

# Editor guidance that is only true once the corresponding module actually
# succeeded. Never prints secrets held in local configuration.
show_editor_completion_notices() {
    if module_completed "vscode_config"; then
        print_info "Visual Studio Code Desktop:"
        echo "  • Settings Sync must be disabled manually for Settings and Extensions."
        echo "    The installer cannot detect or enforce this state; the repository"
        echo "    remains the authority for the managed Default Profile."
    fi

    if module_completed "code_server"; then
        print_info "code-server browser endpoint:"
        echo "  • Local configuration (bind address, generated secrets): ~/.config/code-server/config.yaml"
        echo "  • The endpoint serves HTTPS with a locally generated certificate;"
        echo "    browsers warn until that certificate is accepted or trusted."
        echo "  • Password authentication stays enabled; read the generated value"
        echo "    from the local configuration file rather than from this output."
        echo "  • Reachability is yours to restrict: expose the listener to trusted"
        echo "    private networks only. The installer changes no firewall rules."
    fi
}

# ===========================
# Command Line Arguments
# ===========================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --modules)
                IFS=',' read -ra SELECTED_MODULES <<< "$2"
                shift 2
                ;;
            --profile)
                case $2 in
                    full|minimal|work)
                        # Expansion is deferred until after platform detection.
                        REQUESTED_PROFILE="$2"
                        ;;
                    *)
                        print_error "Unknown profile: $2"
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            --code-server-bind)
                # Runtime-only override; validated before any module runs.
                if [ $# -lt 2 ] || ! split_code_server_bind "$2" >/dev/null; then
                    print_error "Invalid --code-server-bind value: '${2-}' (expected address:port with port 1-65535, e.g. 0.0.0.0:8080 or [::1]:8080)"
                    exit 1
                fi
                CODE_SERVER_BIND="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            --codex-config-template)
                case $2 in
                    preserve|overwrite)
                        CODEX_CONFIG_TEMPLATE_MODE="$2"
                        ;;
                    *)
                        print_error "Unknown value for --codex-config-template: $2 (use preserve or overwrite)"
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
Dotfiles Installation Script

Usage: $0 [OPTIONS]

Options:
  --profile PROFILE    Install predefined profile (full, minimal, work)
  --modules MODULES    Comma-separated list of modules to install
  --codex-config-template MODE
                       Codex config behavior: preserve (default) or overwrite
  --code-server-bind ADDRESS:PORT
                       Override the local code-server bind value for this run
                       (e.g. 0.0.0.0:8080 or [::1]:8080); stored only in local
                       code-server configuration, never in tracked files
  --help              Show this help message

Profiles:
  full                Everything (includes Go development environment)
  minimal             Editors plus terminal workspace (Neovim + Tmux fallback + Herdr)
  work                Work setup (Neovim, Tmux fallback, Herdr, Copilot - no Go)

Modules:
  base_tools          Base tools (git, curl, tmux, zsh, etc.)
  neovim              Neovim 0.12+
  nvim_config         Neovim configuration (kickstart + custom)
  tmux_config         Tmux configuration
  herdr               Herdr terminal workspace manager
  herdr_config        Herdr configuration
  herdr_integrations  Herdr agent integrations
  zsh_ohmyzsh         Zsh + Oh My Zsh
  zsh_config          Zsh custom configuration
  python              Python 3.10+ native interpreter and venv support
  golang              Go 1.24+ toolchain only
  golang_full         Go development (toolchain + LSP + tools + govulncheck)
  nodejs              Node.js LTS (fnm)
  codex               Codex CLI
  codex_sandbox       Codex Sandbox (Docker image + cods script)
  tui_tools           TUI tools (lazygit, yazi, zoxide)
  claude              Claude Code CLI
  pi                  Pi Coding Agent
  pi_sandbox          Pi Sandbox (Docker image + pis script)
  copilot             GitHub Copilot CLI
  playwright          Playwright CLI (browser automation)
  vscode              Visual Studio Code Desktop (macOS only)
  vscode_config       VS Code managed configuration (macOS only)
  code_server         code-server browser endpoint (Ubuntu/Debian, explicit only)

Examples:
  $0                                       # Interactive menu
  $0 --profile full                        # Install everything
  $0 --profile minimal                     # Minimal installation
  $0 --profile work                        # Work profile (no Go)
  $0 --modules neovim,nvim_config,tmux_config  # Custom modules
  $0 --modules herdr,herdr_config,herdr_integrations  # Herdr only
  $0 --modules golang_full,neovim          # Go dev environment
  $0 --modules codex --codex-config-template overwrite  # Refresh ~/.codex/config.toml
  $0 --modules code_server --code-server-bind 0.0.0.0:8080  # Browser endpoint

EOF
}

# ===========================
# Main Installation Flow
# ===========================

main() {
    # Parse command line arguments first (for --help)
    parse_arguments "$@"

    print_header "Dotfiles Installation Script"
    print_info "Dotfiles directory: $DOTFILES_DIR"

    # Core setup (always required)
    detect_os

    # Expand a requested installation profile now that the platform is known.
    if [ -n "$REQUESTED_PROFILE" ]; then
        SELECTED_MODULES=($(expand_profile "$REQUESTED_PROFILE"))
    fi

    setup_package_manager

    # If no modules selected, show interactive menu
    if [ ${#SELECTED_MODULES[@]} -eq 0 ]; then
        show_profile_menu
    fi

    # Resolve dependencies
    print_info "Resolving dependencies..."
    SELECTED_MODULES=($(resolve_dependencies "${SELECTED_MODULES[@]}"))

    if modules_require_package_manager_update "${SELECTED_MODULES[@]}"; then
        update_package_manager
    else
        print_info "Skipping package manager update; selected modules do not install OS packages"
    fi

    # Show summary and confirm
    if ! show_installation_summary; then
        exit 0
    fi

    # Execute installation
    print_header "Starting Installation"
    execute_modules "${SELECTED_MODULES[@]}"

    # Show completion summary
    print_header "Installation Complete"

    if [ ${#FAILED_MODULES[@]} -gt 0 ]; then
        print_warning "Some modules failed to install:"
        for module in "${FAILED_MODULES[@]}"; do
            echo "  ✗ $module"
        done
        echo ""
    fi

    print_success "Successfully installed modules:"
    for module in "${SELECTED_MODULES[@]}"; do
        if [[ ! " ${FAILED_MODULES[@]} " =~ " ${module} " ]]; then
            echo "  ✓ $module"
        fi
    done

    echo ""
    show_editor_completion_notices

    echo ""
    print_info "Next steps:"
    echo "  1. Restart your shell or run: source ~/.zshrc"
    echo "  2. Start Herdr: herdr"
    echo "  3. Launch neovim: nvim"
    echo ""
    print_info "For AI agents:"
    echo "  • Codex: codex login"
    echo "  • Claude Code: claude auth login"
    echo "  • Pi: pi (first launch prompts for auth)"
    echo "  • Copilot CLI: copilot login"
    echo ""
    print_success "Happy coding!"

    # Return non-zero if any modules failed
    if [ ${#FAILED_MODULES[@]} -gt 0 ]; then
        exit 1
    fi
}

# Run main function unless the script is being sourced by tests.
if [ "${INSTALL_SH_NO_MAIN:-0}" != "1" ]; then
    main "$@"
fi
