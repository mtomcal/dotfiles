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

        if [[ $(echo "$NVIM_VERSION < 0.10" | bc -l 2>/dev/null || echo "1") -eq 1 ]]; then
            print_warning "Neovim version is $NVIM_VERSION (recommended: 0.10+)"
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
            print_success "Neovim version is $NVIM_VERSION (meets requirements)"
        fi
    elif [ "$OS" == "macos" ]; then
        print_info "Installing stable Neovim via Homebrew..."
        if ! brew list neovim &> /dev/null; then
            brew install neovim
        else
            brew upgrade neovim || print_success "Neovim is already up to date"
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

## Adding Custom Plugins

Create a new file in `plugins/` directory:

```lua
-- plugins/my-plugin.lua
return {
  'author/plugin-name',
  config = function()
    -- Plugin configuration
  end,
}
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
        if grep -q "^  -- { import = 'custom\.plugins' }," "$HOME/.config/nvim/init.lua"; then
            if [ "$OS" == "macos" ]; then
                sed -i '' "s/^  -- { import = 'custom\.plugins' },/  { import = 'custom.plugins' },/" "$HOME/.config/nvim/init.lua"
            else
                sed -i "s/^  -- { import = 'custom\.plugins' },/  { import = 'custom.plugins' },/" "$HOME/.config/nvim/init.lua"
            fi
            print_success "Custom plugin loading enabled"
        elif grep -q "^  { import = 'custom\.plugins' }," "$HOME/.config/nvim/init.lua"; then
            print_success "Custom plugin loading already enabled"
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

    # Clean cache on fresh installation
    if [ ! -d "$HOME/.local/share/nvim/lazy" ]; then
        print_info "Fresh installation detected - cleaning neovim cache..."
        rm -rf "$HOME/.local/share/nvim"
        rm -rf "$HOME/.local/state/nvim"
        rm -rf "$HOME/.cache/nvim"
    else
        print_info "Preserving existing Mason packages and cache"
        rm -rf "$HOME/.cache/nvim"
    fi

    # Install plugins
    print_info "Installing neovim plugins..."
    if nvim --headless "+Lazy! sync" +qa 2>/dev/null; then
        print_success "Neovim plugins installed"
    else
        print_warning "Plugin installation may require manual intervention"
        print_info "Run: nvim --headless '+Lazy! sync' +qa"
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
    MASON_PACKAGES="stylua ruff pyright"

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

    # Verify installation
    if command -v go &> /dev/null; then
        GO_FULL_VERSION=$(go version)
        print_success "Go verified: $GO_FULL_VERSION"

        export GOROOT="$HOME/go"
        export GOPATH="$HOME/go-workspace"
        mkdir -p "$GOPATH/bin"
        export PATH="$GOPATH/bin:$GOROOT/bin:$PATH"
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
        if go install golang.org/x/vuln/cmd/govulncheck@latest; then
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
        if playwright-cli install --skills 2>/dev/null; then
            print_success "Playwright CLI skills installed"
        else
            print_warning "Failed to install Playwright CLI skills"
        fi
    fi
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

install_opencode() {
    print_header "Installing OpenCode"

    if ! command -v opencode &> /dev/null; then
        print_info "Installing OpenCode CLI..."
        curl -fsSL https://opencode.ai/install | bash
        export PATH="$HOME/.local/bin:$PATH"
        print_success "OpenCode CLI installed"
    else
        print_success "OpenCode CLI is already installed"
    fi

    mkdir -p "$HOME/.config/opencode"

    # Link commands
    if [ -L "$HOME/.config/opencode/command" ]; then
        rm "$HOME/.config/opencode/command"
    elif [ -d "$HOME/.config/opencode/command" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.config/opencode/command" "$HOME/.config/opencode/command.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/opencode/commands" "$HOME/.config/opencode/command"

    # Link agents
    if [ -L "$HOME/.config/opencode/agent" ]; then
        rm "$HOME/.config/opencode/agent"
    elif [ -d "$HOME/.config/opencode/agent" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.config/opencode/agent" "$HOME/.config/opencode/agent.backup.$TIMESTAMP"
    fi
    ln -s "$DOTFILES_DIR/opencode/agents" "$HOME/.config/opencode/agent"

    # Link AGENTS.md
    if [ -f "$HOME/.config/opencode/AGENTS.md" ] && [ ! -L "$HOME/.config/opencode/AGENTS.md" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.config/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md.backup.$TIMESTAMP"
    fi
    if [ -L "$HOME/.config/opencode/AGENTS.md" ]; then
        rm "$HOME/.config/opencode/AGENTS.md"
    fi
    ln -s "$DOTFILES_DIR/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

    # Link config
    if [ -f "$HOME/.config/opencode/opencode.json" ] && [ ! -L "$HOME/.config/opencode/opencode.json" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json.backup.$TIMESTAMP"
    fi
    if [ -L "$HOME/.config/opencode/opencode.json" ]; then
        rm "$HOME/.config/opencode/opencode.json"
    fi
    if [ -f "$DOTFILES_DIR/opencode/opencode.json" ]; then
        ln -s "$DOTFILES_DIR/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
    fi

    print_success "OpenCode configured"
    print_info "Run 'opencode auth login' to authenticate"
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
            "claude"|"opencode")
                # AI agents need curl
                if ! command -v curl &> /dev/null; then
                    print_warning "Adding curl (required by AI agents)"
                    resolved+=("base_tools")
                fi
                resolved+=("$module")
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
    echo "     Neovim, Tmux, OpenCode (no personal tools)"
    echo ""
    echo "  4) Custom (pick components)"
    echo "     Interactive component selection"
    echo ""
    echo "  0) Exit"
    echo ""

    read -p "Enter choice [0-4]: " choice

    case $choice in
        1)
            SELECTED_MODULES=(base_tools neovim nvim_config tmux_config zsh_ohmyzsh zsh_config golang_full nodejs claude playwright opencode)
            ;;
        2)
            SELECTED_MODULES=(base_tools neovim nvim_config tmux_config)
            ;;
        3)
            SELECTED_MODULES=(base_tools neovim nvim_config tmux_config opencode)
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

    declare -A selections
    local options=(
        "base_tools:Base Tools (git, curl, tmux, zsh, etc.)"
        "neovim:Neovim 0.10+"
        "nvim_config:Neovim Configuration (kickstart + custom)"
        "tmux_config:Tmux Configuration"
        "zsh_ohmyzsh:Zsh + Oh My Zsh"
        "zsh_config:Zsh Custom Configuration"
        "golang_full:Go Development (toolchain + LSP + tools)"
        "nodejs:Node.js LTS (fnm)"
        "claude:Claude Code CLI"
        "opencode:OpenCode CLI"
        "playwright:Playwright CLI (browser automation)"
    )

    # Initialize all as unselected
    for opt in "${options[@]}"; do
        key="${opt%%:*}"
        selections[$key]=0
    done

    while true; do
        clear
        print_header "Select Components"

        echo "Current selections:"
        for opt in "${options[@]}"; do
            key="${opt%%:*}"
            desc="${opt#*:}"
            if [ "${selections[$key]}" == "1" ]; then
                echo "  [X] $desc"
            else
                echo "  [ ] $desc"
            fi
        done

        echo ""
        echo "Options:"
        local i=1
        for opt in "${options[@]}"; do
            desc="${opt#*:}"
            echo "  $i) $desc"
            ((i++))
        done
        echo "  12) Toggle All"
        echo "  13) Done"
        echo ""

        read -p "Enter number to toggle (or 13 when done): " choice

        if [ "$choice" == "13" ]; then
            break
        elif [ "$choice" == "12" ]; then
            # Toggle all
            local all_selected=1
            for key in "${!selections[@]}"; do
                if [ "${selections[$key]}" == "0" ]; then
                    all_selected=0
                    break
                fi
            done

            for key in "${!selections[@]}"; do
                if [ "$all_selected" == "1" ]; then
                    selections[$key]=0
                else
                    selections[$key]=1
                fi
            done
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            # Toggle individual selection
            local idx=$((choice - 1))
            local opt="${options[$idx]}"
            local key="${opt%%:*}"
            if [ "${selections[$key]}" == "1" ]; then
                selections[$key]=0
            else
                selections[$key]=1
            fi
        else
            print_error "Invalid choice"
            sleep 1
        fi
    done

    # Build selected modules array
    SELECTED_MODULES=()
    for opt in "${options[@]}"; do
        key="${opt%%:*}"
        if [ "${selections[$key]}" == "1" ]; then
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
            "neovim") echo "  • Neovim 0.10+" ;;
            "nvim_config") echo "  • Neovim Configuration (kickstart + custom)" ;;
            "tmux_config") echo "  • Tmux Configuration" ;;
            "zsh_ohmyzsh") echo "  • Zsh + Oh My Zsh" ;;
            "zsh_config") echo "  • Zsh Custom Configuration" ;;
            "golang") echo "  • Go 1.24+ Toolchain (basic)" ;;
            "golang_full") echo "  • Go Development (toolchain + LSP + tools + govulncheck)" ;;
            "nodejs") echo "  • Node.js LTS (fnm)" ;;
            "claude") echo "  • Claude Code CLI" ;;
            "opencode") echo "  • OpenCode CLI" ;;
            "playwright") echo "  • Playwright CLI (browser automation)" ;;
        esac
    done

    echo ""
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
            "claude")
                if ! install_claude; then
                    FAILED_MODULES+=("claude")
                fi
                ;;
            "opencode")
                if ! install_opencode; then
                    FAILED_MODULES+=("opencode")
                fi
                ;;
            "playwright")
                if ! install_playwright; then
                    FAILED_MODULES+=("playwright")
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
                        SELECTED_MODULES=(base_tools neovim nvim_config tmux_config zsh_ohmyzsh zsh_config golang_full nodejs claude playwright opencode)
                        ;;
                    minimal)
                        SELECTED_MODULES=(base_tools neovim nvim_config tmux_config)
                        ;;
                    work)
                        SELECTED_MODULES=(base_tools neovim nvim_config tmux_config opencode)
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
  --help              Show this help message

Profiles:
  full                Everything (includes Go development environment)
  minimal             Editors only (Neovim + Tmux)
  work                Work setup (Neovim, Tmux, OpenCode - no Go)

Modules:
  base_tools          Base tools (git, curl, tmux, zsh, etc.)
  neovim              Neovim 0.10+
  nvim_config         Neovim configuration (kickstart + custom)
  tmux_config         Tmux configuration
  zsh_ohmyzsh         Zsh + Oh My Zsh
  zsh_config          Zsh custom configuration
  golang              Go 1.24+ toolchain only
  golang_full         Go development (toolchain + LSP + tools + govulncheck)
  nodejs              Node.js LTS (fnm)
  claude              Claude Code CLI
  opencode            OpenCode CLI
  playwright          Playwright CLI (browser automation)

Examples:
  $0                                       # Interactive menu
  $0 --profile full                        # Install everything
  $0 --profile minimal                     # Minimal installation
  $0 --profile work                        # Work profile (no Go)
  $0 --modules neovim,nvim_config,tmux     # Custom modules
  $0 --modules golang_full,neovim          # Go dev environment

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
    update_package_manager

    # If no modules selected, show interactive menu
    if [ ${#SELECTED_MODULES[@]} -eq 0 ]; then
        show_profile_menu
    fi

    # Resolve dependencies
    print_info "Resolving dependencies..."
    SELECTED_MODULES=($(resolve_dependencies "${SELECTED_MODULES[@]}"))

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
    echo "  • Claude Code: claude auth login"
    echo "  • OpenCode: opencode auth login"
    echo ""
    print_success "Happy coding!"

    # Return non-zero if any modules failed
    if [ ${#FAILED_MODULES[@]} -gt 0 ]; then
        exit 1
    fi
}

# Run main function
main "$@"
