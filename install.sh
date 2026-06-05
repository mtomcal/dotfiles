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
CODEX_CONFIG_TEMPLATE_MODE="preserve"

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

    if ! command -v claude &> /dev/null; then
        print_info "Installing Claude Code CLI..."
        curl -fsSL https://claude.ai/install.sh | bash
        export PATH="$HOME/.local/bin:$PATH"
        print_success "Claude Code CLI installed"
    else
        print_success "Claude Code CLI is already installed"
    fi

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

    # Link settings
    if [ -f "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup.$TIMESTAMP"
    fi
    if [ -L "$HOME/.claude/settings.json" ]; then
        rm "$HOME/.claude/settings.json"
    fi
    if [ -f "$DOTFILES_DIR/claude/settings.json" ]; then
        ln -s "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
    fi

    # Link statusline
    if [ -L "$HOME/.claude/statusline.sh" ]; then
        rm "$HOME/.claude/statusline.sh"
    elif [ -f "$HOME/.claude/statusline.sh" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.claude/statusline.sh" "$HOME/.claude/statusline.sh.backup.$TIMESTAMP"
    fi
    if [ -f "$DOTFILES_DIR/claude/statusline.sh" ]; then
        ln -s "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
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

    deploy_pi_profiles || return 1

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

deploy_pi_profile_runtime() {
    local profile="$1"
    local resolved="$DOTFILES_DIR/pi/profiles/$profile/resolved"
    local runtime="$HOME/.pi/profiles/$profile/agent"
    local extension

    if [ ! -d "$resolved" ]; then
        print_error "Pi profile '$profile' is missing resolved output: $resolved"
        return 1
    fi
    for required in settings.json models.json agents skills; do
        if [ ! -e "$resolved/$required" ] && [ ! -L "$resolved/$required" ]; then
            print_error "Pi profile '$profile' resolved output is missing $required"
            return 1
        fi
    done

    mkdir -p "$runtime/extensions" "$runtime/sessions"
    replace_symlink "$resolved/settings.json" "$runtime/settings.json"
    replace_symlink "$resolved/models.json" "$runtime/models.json"
    replace_symlink "$resolved/agents" "$runtime/agents"
    replace_symlink "$resolved/skills" "$runtime/skills"
    replace_symlink "$HOME/.pi/auth.json" "$runtime/auth.json"

    if [ -d "$resolved/extensions" ]; then
        for extension in "$resolved/extensions"/*; do
            [ -e "$extension" ] || [ -L "$extension" ] || continue
            replace_symlink "$extension" "$runtime/extensions/$(basename "$extension")"
        done
    fi
}

prepare_pi_shared_auth() {
    mkdir -p "$HOME/.pi"
    if [ -f "$HOME/.pi/auth.json" ]; then
        return 0
    fi

    if [ ! -L "$HOME/.pi/agent" ] && [ -f "$HOME/.pi/agent/auth.json" ]; then
        cp "$HOME/.pi/agent/auth.json" "$HOME/.pi/auth.json"
    else
        printf '{}\n' > "$HOME/.pi/auth.json"
    fi
}

deploy_pi_wrappers() {
    local bin_dir="$HOME/.local/bin"
    local profile_dir profile
    mkdir -p "$bin_dir"

    replace_symlink "$DOTFILES_DIR/pi/pim.sh" "$bin_dir/pim"
    replace_symlink "$DOTFILES_DIR/pi/pi.sh" "$bin_dir/pi"
    replace_symlink "$DOTFILES_DIR/pi/pis.sh" "$bin_dir/pis"

    for profile_dir in "$DOTFILES_DIR/pi/profiles"/*; do
        [ -d "$profile_dir" ] || continue
        profile="$(basename "$profile_dir")"
        replace_symlink "$DOTFILES_DIR/pi/pi.sh" "$bin_dir/pi-$profile"
        replace_symlink "$DOTFILES_DIR/pi/pis.sh" "$bin_dir/pis-$profile"
    done
}

deploy_pi_profiles() {
    local profiles_dir="$DOTFILES_DIR/pi/profiles"
    local profile_dir profile active_profile active_runtime

    if [ ! -d "$profiles_dir" ]; then
        print_error "Pi profiles directory not found: $profiles_dir"
        return 1
    fi

    prepare_pi_shared_auth

    for profile_dir in "$profiles_dir"/*; do
        [ -d "$profile_dir" ] || continue
        profile="$(basename "$profile_dir")"
        deploy_pi_profile_runtime "$profile" || return 1
    done

    mkdir -p "$HOME/.pi"
    if [ -f "$HOME/.pi/active-profile" ]; then
        active_profile="$(sed -n '1p' "$HOME/.pi/active-profile")"
    else
        active_profile="coding"
    fi
    if [ ! -d "$HOME/.pi/profiles/$active_profile/agent" ]; then
        active_profile="coding"
    fi
    active_runtime="$HOME/.pi/profiles/$active_profile/agent"
    if [ ! -d "$active_runtime" ]; then
        print_error "Active Pi profile runtime not found: $active_runtime"
        return 1
    fi

    replace_symlink "$active_runtime" "$HOME/.pi/agent"
    printf '%s\n' "$active_profile" > "$HOME/.pi/active-profile"
    deploy_pi_wrappers
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

install_gemini() {
    print_header "Installing Gemini CLI"

    # Gemini CLI is distributed as an npm package.
    # Install to ~/.local so it is shared across fnm Node versions
    # (same pattern as Codex CLI).
    if ! command -v npm &> /dev/null; then
        print_warning "npm not found. Installing Node.js first..."
        install_nodejs || return 1
    fi

    mkdir -p "$HOME/.local/bin"
    print_info "Installing/updating Gemini CLI via npm into ~/.local..."
    npm install -g --prefix "$HOME/.local" @google/gemini-cli@latest

    if [ ! -x "$HOME/.local/bin/gemini" ]; then
        print_error "Gemini CLI install failed: ~/.local/bin/gemini not found"
        return 1
    fi

    if command -v gemini &> /dev/null && [ "$(command -v gemini)" != "$HOME/.local/bin/gemini" ]; then
        print_warning "Another gemini binary is earlier in PATH: $(command -v gemini)"
        print_info "Ensure ~/.local/bin is first in PATH to use the shared Gemini install"
    fi
    print_success "Gemini CLI installed/updated at ~/.local/bin/gemini"

    mkdir -p "$HOME/.gemini"

    # Link settings.json
    if [ -f "$HOME/.gemini/settings.json" ] && [ ! -L "$HOME/.gemini/settings.json" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.gemini/settings.json" "$HOME/.gemini/settings.json.backup.$TIMESTAMP"
        print_warning "Backed up existing ~/.gemini/settings.json"
    fi
    if [ -L "$HOME/.gemini/settings.json" ]; then
        rm "$HOME/.gemini/settings.json"
    fi
    if [ -f "$DOTFILES_DIR/gemini/settings.json" ]; then
        ln -s "$DOTFILES_DIR/gemini/settings.json" "$HOME/.gemini/settings.json"
    fi

    # Link commands directory
    if [ -L "$HOME/.gemini/commands" ]; then
        rm "$HOME/.gemini/commands"
    elif [ -d "$HOME/.gemini/commands" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.gemini/commands" "$HOME/.gemini/commands.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/gemini/commands" "$HOME/.gemini/commands"

    # Link agents directory
    if [ -L "$HOME/.gemini/agents" ]; then
        rm "$HOME/.gemini/agents"
    elif [ -d "$HOME/.gemini/agents" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.gemini/agents" "$HOME/.gemini/agents.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/gemini/agents" "$HOME/.gemini/agents"

    # Link skills directory
    if [ -L "$HOME/.gemini/skills" ]; then
        rm "$HOME/.gemini/skills"
    elif [ -d "$HOME/.gemini/skills" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.gemini/skills" "$HOME/.gemini/skills.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/shared/skills" "$HOME/.gemini/skills"

    print_success "Gemini CLI configured"
    print_info "Run 'gemini' to authenticate (Google account / API key)"
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
                    print_warning "Adding git (required by neovim config)"
                    resolved+=("base_tools")
                fi
                if ! command -v nvim &> /dev/null; then
                    print_warning "Adding neovim (required by neovim config)"
                    resolved+=("neovim")
                fi
                resolved+=("nvim_config")
                ;;
            "zsh_ohmyzsh")
                # Oh My Zsh needs zsh and git
                if ! command -v zsh &> /dev/null; then
                    print_warning "Adding zsh (required by Oh My Zsh)"
                    resolved+=("base_tools")
                fi
                if ! command -v git &> /dev/null; then
                    print_warning "Adding git (required by Oh My Zsh)"
                    resolved+=("base_tools")
                fi
                resolved+=("zsh_ohmyzsh")
                ;;
            "tmux_config")
                # Tmux config needs tmux
                if ! command -v tmux &> /dev/null; then
                    print_warning "Adding tmux (required by tmux config)"
                    resolved+=("base_tools")
                fi
                resolved+=("tmux_config")
                ;;
            "zsh_config")
                # Zsh config needs zsh
                if ! command -v zsh &> /dev/null; then
                    print_warning "Adding zsh (required by zsh config)"
                    resolved+=("base_tools")
                fi
                resolved+=("zsh_config")
                ;;
            "claude")
                # Claude Code needs curl
                if ! command -v curl &> /dev/null; then
                    print_warning "Adding curl (required by Claude Code)"
                    resolved+=("base_tools")
                fi
                resolved+=("claude")
                ;;
            "pi")
                # Pi coding agent uses npm
                if ! command -v npm &> /dev/null; then
                    print_warning "Adding Node.js (required by Pi coding agent)"
                    resolved+=("nodejs")
                fi
                resolved+=("pi")
                ;;
            "pi_sandbox")
                # Pi sandbox needs Docker (not installed by this script) and pi
                if ! command -v docker &> /dev/null; then
                    print_warning "Docker required for Pi sandbox (install Docker separately)"
                fi
                resolved+=("pi_sandbox")
                ;;
            "codex_sandbox")
                # Codex sandbox needs Docker (not installed by this script), npm, and Codex config.
                if ! command -v docker &> /dev/null; then
                    print_warning "Docker required for Codex sandbox (install Docker separately)"
                fi
                if ! command -v npm &> /dev/null; then
                    print_warning "Adding Node.js (required by Codex sandbox)"
                    resolved+=("nodejs")
                fi
                resolved+=("codex")
                resolved+=("codex_sandbox")
                ;;
            "codex")
                # Codex CLI install uses npm
                if ! command -v npm &> /dev/null; then
                    print_warning "Adding Node.js (required by Codex CLI)"
                    resolved+=("nodejs")
                fi
                resolved+=("codex")
                ;;
            "gemini")
                # Gemini CLI install uses npm
                if ! command -v npm &> /dev/null; then
                    print_warning "Adding Node.js (required by Gemini CLI)"
                    resolved+=("nodejs")
                fi
                resolved+=("gemini")
                ;;
            "copilot")
                # Copilot CLI uses curl installer
                if ! command -v curl &> /dev/null; then
                    print_warning "Adding curl (required by Copilot CLI)"
                    resolved+=("base_tools")
                fi
                resolved+=("copilot")
                ;;
            "playwright")
                # Playwright CLI needs npm (Node.js)
                if ! command -v npm &> /dev/null; then
                    print_warning "Adding Node.js (required by Playwright CLI)"
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
# Menu System
# ===========================

show_profile_menu() {
    print_header "Dotfiles Installation"

    echo "Select installation profile:"
    echo ""
    echo "  1) Full Installation"
    echo "     Everything: Neovim, Tmux, Zsh, Go, Node.js, AI agents"
    echo ""
    echo "  2) Minimal (editors only)"
    echo "     Neovim + config, Tmux + config"
    echo ""
    echo "  3) Work Profile"
    echo "     Neovim, Tmux, TUI tools, Copilot CLI"
    echo ""
    echo "  4) Custom (pick components)"
    echo "     Interactive component selection"
    echo ""
    echo "  0) Exit"
    echo ""

    read -p "Enter choice [0-4]: " choice

    case $choice in
        1)
            SELECTED_MODULES=(base_tools neovim nvim_config tmux_config zsh_ohmyzsh zsh_config golang_full nodejs tui_tools codex codex_sandbox claude playwright pi pi_sandbox gemini copilot)
            ;;
        2)
            SELECTED_MODULES=(base_tools neovim nvim_config tmux_config)
            ;;
        3)
            SELECTED_MODULES=(base_tools neovim nvim_config tmux_config tui_tools copilot)
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
    local options=(
        "base_tools:Base Tools (git, curl, tmux, zsh, etc.)"
        "neovim:Neovim 0.12+"
        "nvim_config:Neovim Configuration (kickstart + custom)"
        "tmux_config:Tmux Configuration"
        "zsh_ohmyzsh:Zsh + Oh My Zsh"
        "zsh_config:Zsh Custom Configuration"
        "golang_full:Go Development (toolchain + LSP + tools)"
        "nodejs:Node.js LTS (fnm)"
        "codex:Codex CLI"
        "codex_sandbox:Codex Sandbox (Docker)"
        "claude:Claude Code CLI"
        "pi:Pi Coding Agent"
        "pi_sandbox:Pi Sandbox (Docker)"
        "gemini:Gemini CLI"
        "tui_tools:TUI Tools (lazygit, yazi, zoxide)"
        "playwright:Playwright CLI (browser automation)"
        "copilot:GitHub Copilot CLI"
    )
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
        case "$module" in
            "base_tools") echo "  • Base Tools (git, curl, tmux, zsh, etc.)" ;;
            "neovim") echo "  • Neovim 0.12+" ;;
            "nvim_config") echo "  • Neovim Configuration (kickstart + custom)" ;;
            "tmux_config") echo "  • Tmux Configuration" ;;
            "zsh_ohmyzsh") echo "  • Zsh + Oh My Zsh" ;;
            "zsh_config") echo "  • Zsh Custom Configuration" ;;
            "golang") echo "  • Go 1.24+ Toolchain (basic)" ;;
            "golang_full") echo "  • Go Development (toolchain + LSP + tools + govulncheck)" ;;
            "nodejs") echo "  • Node.js LTS (fnm)" ;;
            "codex") echo "  • Codex CLI" ;;
            "codex_sandbox") echo "  • Codex Sandbox (Docker)" ;;
            "claude") echo "  • Claude Code CLI" ;;
            "pi") echo "  • Pi Coding Agent" ;;
            "pi_sandbox") echo "  • Pi Sandbox (Docker)" ;;
            "gemini") echo "  • Gemini CLI" ;;
            "tui_tools") echo "  • TUI Tools (lazygit, yazi, zoxide)" ;;
            "playwright") echo "  • Playwright CLI (browser automation)" ;;
            "copilot") echo "  • GitHub Copilot CLI" ;;
        esac
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

execute_modules() {
    local modules=("$@")

    for module in "${modules[@]}"; do
        case "$module" in
            "base_tools")
                if ! install_base_tools; then
                    FAILED_MODULES+=("base_tools")
                fi
                ;;
            "neovim")
                if ! install_neovim; then
                    FAILED_MODULES+=("neovim")
                fi
                ;;
            "nvim_config")
                if ! configure_neovim; then
                    FAILED_MODULES+=("nvim_config")
                fi
                ;;
            "tmux_config")
                if ! configure_tmux; then
                    FAILED_MODULES+=("tmux_config")
                fi
                ;;
            "zsh_ohmyzsh")
                if ! install_zsh; then
                    FAILED_MODULES+=("zsh_ohmyzsh")
                fi
                ;;
            "zsh_config")
                if ! configure_zsh; then
                    FAILED_MODULES+=("zsh_config")
                fi
                ;;
            "golang")
                if ! install_golang; then
                    FAILED_MODULES+=("golang")
                fi
                ;;
            "golang_full")
                if ! install_golang_full; then
                    FAILED_MODULES+=("golang_full")
                fi
                ;;
            "nodejs")
                if ! install_nodejs; then
                    FAILED_MODULES+=("nodejs")
                fi
                ;;
            "codex")
                if ! install_codex; then
                    FAILED_MODULES+=("codex")
                fi
                ;;
            "codex_sandbox")
                if ! install_codex_sandbox; then
                    FAILED_MODULES+=("codex_sandbox")
                fi
                ;;
            "gemini")
                if ! install_gemini; then
                    FAILED_MODULES+=("gemini")
                fi
                ;;
            "claude")
                if ! install_claude; then
                    FAILED_MODULES+=("claude")
                fi
                ;;
            "pi")
                if ! install_pi; then
                    FAILED_MODULES+=("pi")
                fi
                ;;
            "pi_sandbox")
                if ! install_pi_sandbox; then
                    FAILED_MODULES+=("pi_sandbox")
                fi
                ;;
            "tui_tools")
                if ! install_tui_tools; then
                    FAILED_MODULES+=("tui_tools")
                fi
                ;;
            "playwright")
                if ! install_playwright; then
                    FAILED_MODULES+=("playwright")
                fi
                ;;
            "copilot")
                if ! install_copilot; then
                    FAILED_MODULES+=("copilot")
                fi
                ;;
        esac
    done
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
                    full)
                        SELECTED_MODULES=(base_tools neovim nvim_config tmux_config zsh_ohmyzsh zsh_config golang_full nodejs tui_tools codex codex_sandbox claude playwright pi pi_sandbox gemini copilot)
                        ;;
                    minimal)
                        SELECTED_MODULES=(base_tools neovim nvim_config tmux_config)
                        ;;
                    work)
                        SELECTED_MODULES=(base_tools neovim nvim_config tmux_config tui_tools copilot)
                        ;;
                    *)
                        print_error "Unknown profile: $2"
                        exit 1
                        ;;
                esac
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
  --help              Show this help message

Profiles:
  full                Everything (includes Go development environment)
  minimal             Editors only (Neovim + Tmux)
  work                Work setup (Neovim, Tmux, Copilot - no Go)

Modules:
  base_tools          Base tools (git, curl, tmux, zsh, etc.)
  neovim              Neovim 0.12+
  nvim_config         Neovim configuration (kickstart + custom)
  tmux_config         Tmux configuration
  zsh_ohmyzsh         Zsh + Oh My Zsh
  zsh_config          Zsh custom configuration
  golang              Go 1.24+ toolchain only
  golang_full         Go development (toolchain + LSP + tools + govulncheck)
  nodejs              Node.js LTS (fnm)
  codex               Codex CLI
  codex_sandbox       Codex Sandbox (Docker image + cods script)
  tui_tools           TUI tools (lazygit, yazi, zoxide)
  claude              Claude Code CLI
  pi                  Pi Coding Agent
  pi_sandbox          Pi Sandbox (Docker image + pis script)
  gemini              Gemini CLI
  copilot             GitHub Copilot CLI
  playwright          Playwright CLI (browser automation)

Examples:
  $0                                       # Interactive menu
  $0 --profile full                        # Install everything
  $0 --profile minimal                     # Minimal installation
  $0 --profile work                        # Work profile (no Go)
  $0 --modules neovim,nvim_config,tmux_config  # Custom modules
  $0 --modules golang_full,neovim          # Go dev environment
  $0 --modules codex --codex-config-template overwrite  # Refresh ~/.codex/config.toml

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
    print_info "Next steps:"
    echo "  1. Restart your shell or run: source ~/.zshrc"
    echo "  2. Start tmux: tmux"
    echo "  3. Launch neovim: nvim"
    echo ""
    print_info "For AI agents:"
    echo "  • Codex: codex login"
    echo "  • Claude Code: claude auth login"
    echo "  • Pi: pi (first launch prompts for auth)"
    echo "  • Gemini CLI: gemini (first run prompts for auth)"
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
