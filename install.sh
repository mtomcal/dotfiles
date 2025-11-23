#!/bin/bash

# ===========================
# Dotfiles Installation Script
# ===========================
# Automated setup for tmux + neovim + zsh development environment
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
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Get the dotfiles directory
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
print_info "Dotfiles directory: $DOTFILES_DIR"

# ===========================
# Detect OS
# ===========================

print_info "Detecting operating system..."

OS=""
PACKAGE_MANAGER=""

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

# ===========================
# Install Package Manager (macOS only)
# ===========================

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

# ===========================
# Install Dependencies
# ===========================

print_info "Installing system dependencies..."

install_package() {
    local package=$1
    local brew_name=${2:-$package}  # Use different name for brew if provided

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

# Update package lists
if [ "$PACKAGE_MANAGER" == "apt" ]; then
    sudo apt update
elif [ "$PACKAGE_MANAGER" == "brew" ]; then
    brew update
fi

# Install packages (package_name apt_name brew_name)
install_package "git" "git"
install_package "curl" "curl"
install_package "tmux" "tmux"
# Note: Neovim is installed later via AppImage (Ubuntu) or brew (macOS)
install_package "ripgrep" "ripgrep"
install_package "zsh" "zsh"

# Platform-specific packages
if [ "$OS" == "ubuntu" ]; then
    install_package "build-essential"
    install_package "fd-find"
    install_package "xclip"
    install_package "python3-venv"  # Required for Mason to install Python tools
elif [ "$OS" == "macos" ]; then
    install_package "gcc" "gcc"
    install_package "fd" "fd"
    # macOS uses pbcopy/pbpaste built-in, no xclip needed
    # macOS Python includes venv by default, no additional package needed
fi

# ===========================
# Install Latest Neovim
# ===========================

if [ "$OS" == "ubuntu" ]; then
    print_info "Checking Neovim version..."

    # Check if nvim exists and get version
    if command -v nvim &> /dev/null; then
        NVIM_VERSION=$(nvim --version 2>/dev/null | head -n1 | grep -oP 'v\K[0-9]+\.[0-9]+' || echo "0.0")
    else
        NVIM_VERSION="0.0"
    fi

    if [[ $(echo "$NVIM_VERSION < 0.10" | bc -l 2>/dev/null || echo "1") -eq 1 ]]; then
        print_warning "Neovim version is $NVIM_VERSION (recommended: 0.10+)"
        read -p "Would you like to install latest stable Neovim via AppImage? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installing Neovim via AppImage..."

            # Remove any existing apt-installed neovim to avoid conflicts
            if dpkg -l | grep -q "^ii  neovim "; then
                print_info "Removing apt-installed neovim..."
                sudo apt remove -y neovim neovim-runtime 2>/dev/null || true
            fi

            # Get latest stable release version
            LATEST_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases | grep '"tag_name"' | grep -v 'nightly\|stable' | head -1 | cut -d'"' -f4)

            if [ -z "$LATEST_VERSION" ]; then
                print_error "Failed to fetch latest Neovim version"
                exit 1
            fi

            print_info "Downloading Neovim $LATEST_VERSION..."

            # Create temp directory
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
                exit 1
            fi

            # Download AppImage
            curl -LO "https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/${APPIMAGE_NAME}"

            # Make it executable
            chmod +x "$APPIMAGE_NAME"

            # Install to /usr/local/bin (requires sudo) or ~/.local/bin (no sudo)
            if [ -w /usr/local/bin ]; then
                mv "$APPIMAGE_NAME" /usr/local/bin/nvim
                print_success "Neovim installed to /usr/local/bin/nvim"
            else
                mkdir -p "$HOME/.local/bin"
                mv "$APPIMAGE_NAME" "$HOME/.local/bin/nvim"
                print_success "Neovim installed to ~/.local/bin/nvim"

                # Add to PATH if not already there
                if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                    print_info "Note: Add ~/.local/bin to your PATH if not already done"
                fi
            fi

            # Cleanup
            cd - > /dev/null
            rm -rf "$TMP_DIR"

            # Verify installation
            INSTALLED_VERSION=$(nvim --version | head -n1 | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+')
            print_success "Neovim $INSTALLED_VERSION installed successfully"
        fi
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

# ===========================
# Install Oh My Zsh
# ===========================

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_success "Oh My Zsh installed"
else
    print_success "Oh My Zsh is already installed"
fi

# Set zsh as default shell if not already
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "zsh" ]; then
    print_info "Current shell is $CURRENT_SHELL, changing to zsh..."

    ZSH_PATH=$(which zsh)
    if [ -z "$ZSH_PATH" ]; then
        print_error "zsh not found in PATH"
        exit 1
    fi

    if [ "$OS" == "macos" ]; then
        # macOS uses chsh differently
        chsh -s "$ZSH_PATH"
    else
        # Ubuntu
        chsh -s "$ZSH_PATH"
    fi

    print_success "Default shell set to zsh (restart required)"
else
    print_success "zsh is already the default shell"
fi

# ===========================
# Install fnm (Fast Node Manager)
# ===========================

if ! command -v fnm &> /dev/null; then
    print_info "Installing fnm (Fast Node Manager)..."

    # Install fnm using the official installer
    curl -fsSL https://fnm.vercel.app/install | bash

    # Set up fnm path for this session
    export PATH="$HOME/.local/share/fnm:$PATH"

    print_success "fnm installed"
else
    print_success "fnm is already installed"
fi

# Install latest LTS Node.js via fnm
if command -v fnm &> /dev/null; then
    print_info "Installing Node.js LTS via fnm..."

    # Temporarily enable fnm for this session
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env --use-on-cd --shell bash)"

    # Install and use latest LTS
    fnm install --lts
    fnm use lts-latest
    fnm default lts-latest

    print_success "Node.js LTS installed and set as default"

    # Show installed version
    NODE_VERSION=$(node --version 2>/dev/null || echo "unknown")
    print_info "Node.js version: $NODE_VERSION"
fi

# ===========================
# Tmux Configuration
# ===========================

print_info "Setting up tmux configuration..."

# Backup existing tmux config if it exists
if [ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
    print_warning "Backing up existing .tmux.conf to .tmux.conf.backup"
    mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup"
fi

# Create symlink
if [ -L "$HOME/.tmux.conf" ]; then
    rm "$HOME/.tmux.conf"
fi

ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
print_success "Tmux configuration linked"

# ===========================
# Zsh Configuration
# ===========================

print_info "Setting up zsh configuration..."

# Check if custom config is already sourced in .zshrc
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

# ===========================
# Neovim Configuration
# ===========================

print_info "Setting up neovim configuration..."

# Handle existing neovim config
if [ -d "$HOME/.config/nvim" ]; then
    # Check if it's a git repo
    if [ -d "$HOME/.config/nvim/.git" ]; then
        print_info "Found existing kickstart.nvim installation"

        # Check if it's the official kickstart repo
        REMOTE_URL=$(cd "$HOME/.config/nvim" && git remote get-url origin 2>/dev/null || echo "")

        if [[ "$REMOTE_URL" == *"nvim-lua/kickstart.nvim"* ]]; then
            print_info "Updating kickstart.nvim to latest version..."
            cd "$HOME/.config/nvim"
            git fetch origin
            git reset --hard origin/master
            print_success "Kickstart.nvim updated"
        else
            print_warning "Existing nvim config is not official kickstart.nvim"
            print_warning "Remote: $REMOTE_URL"
            read -p "Replace with official kickstart.nvim? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                TIMESTAMP=$(date +%Y%m%d_%H%M%S)
                mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$TIMESTAMP"
                print_success "Backed up to ~/.config/nvim.backup.$TIMESTAMP"

                print_info "Cloning official kickstart.nvim..."
                git clone https://github.com/nvim-lua/kickstart.nvim.git "$HOME/.config/nvim"
                print_success "Official kickstart.nvim cloned"
            else
                print_warning "Keeping existing config - skipping kickstart setup"
            fi
        fi
    else
        print_warning "Non-git neovim config exists at ~/.config/nvim"
        read -p "Backup and replace with kickstart.nvim? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$TIMESTAMP"
            print_success "Backed up to ~/.config/nvim.backup.$TIMESTAMP"

            print_info "Cloning official kickstart.nvim..."
            git clone https://github.com/nvim-lua/kickstart.nvim.git "$HOME/.config/nvim"
            print_success "Official kickstart.nvim cloned"
        fi
    fi
else
    print_info "Cloning official kickstart.nvim..."
    mkdir -p "$HOME/.config"
    git clone https://github.com/nvim-lua/kickstart.nvim.git "$HOME/.config/nvim"
    print_success "Official kickstart.nvim cloned"
fi

# Create custom config directory in dotfiles if it doesn't exist
mkdir -p "$DOTFILES_DIR/nvim/custom/plugins"

# Create a placeholder README in custom directory
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
    print_warning "Backing up existing custom config..."
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mv "$HOME/.config/nvim/lua/custom" "$HOME/.config/nvim/lua/custom.backup.$TIMESTAMP"
fi

ln -sf "$DOTFILES_DIR/nvim/custom" "$HOME/.config/nvim/lua/custom"
print_success "Custom neovim config linked"

# Enable custom plugins in kickstart.nvim init.lua
print_info "Enabling custom plugin loading in kickstart.nvim..."
if [ -f "$HOME/.config/nvim/init.lua" ]; then
    # Check if the import line is commented out
    if grep -q "^  -- { import = 'custom.plugins' }," "$HOME/.config/nvim/init.lua"; then
        # Uncomment the import line using sed (handle macOS vs Linux differences)
        if [ "$OS" == "macos" ]; then
            sed -i '' "s/^  -- { import = 'custom\.plugins' },/  { import = 'custom.plugins' },/" "$HOME/.config/nvim/init.lua"
        else
            sed -i "s/^  -- { import = 'custom\.plugins' },/  { import = 'custom.plugins' },/" "$HOME/.config/nvim/init.lua"
        fi
        print_success "Custom plugin loading enabled"
    elif grep -q "^  { import = 'custom.plugins' }," "$HOME/.config/nvim/init.lua"; then
        print_success "Custom plugin loading already enabled"
    else
        print_warning "Could not find custom.plugins import line in init.lua"
    fi
else
    print_warning "init.lua not found at ~/.config/nvim/init.lua"
fi

# Only clean cache on fresh installation (not when updating dotfiles)
if [ ! -d "$HOME/.local/share/nvim/lazy" ]; then
    print_info "Fresh installation detected - cleaning neovim cache..."
    rm -rf "$HOME/.local/share/nvim"
    rm -rf "$HOME/.local/state/nvim"
    rm -rf "$HOME/.cache/nvim"
else
    print_info "Existing neovim installation detected - preserving Mason packages and cache"
    # Only clean the cache, preserve data (Mason packages)
    rm -rf "$HOME/.cache/nvim"
fi

# Install neovim plugins
print_info "Installing neovim plugins (this may take a minute)..."
if nvim --headless "+Lazy! sync" +qa 2>/dev/null; then
    print_success "Neovim plugins installed"
else
    print_warning "Neovim plugin installation encountered an issue"
    print_info "This is often a one-time issue. Plugins will install when you first launch nvim"
    print_info "You can manually install plugins later by running: nvim --headless '+Lazy! sync' +qa"
fi

# Install Mason packages for Python development
print_info "Installing Mason packages for Python development..."
if nvim --headless "+MasonInstall ruff pyright" +qa 2>/dev/null; then
    print_success "Mason packages installed (ruff, pyright)"
else
    print_warning "Mason package installation encountered an issue"
    print_info "You can manually install Mason packages later by running: :Mason in nvim"
fi

# ===========================
# AI Coding Agents (Optional)
# ===========================

print_header "AI Coding Agents Setup"
echo ""
read -p "Install AI coding agents? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # ===========================
    # Claude Code Configuration
    # ===========================

    print_header "Setting up Claude Code"

    # Install Claude Code if not already installed
    if ! command -v claude &> /dev/null; then
        print_info "Installing Claude Code CLI..."
        curl -fsSL https://claude.ai/install.sh | bash

        # Add Claude Code to PATH for this session
        export PATH="$HOME/.local/bin:$PATH"

        print_success "Claude Code CLI installed"
    else
        print_success "Claude Code CLI is already installed"
    fi

    # Create .claude directory if it doesn't exist
    if [ ! -d "$HOME/.claude" ]; then
        print_info "Creating ~/.claude directory..."
        mkdir -p "$HOME/.claude"
        print_success "Created ~/.claude directory"
    fi

    # Link Claude Code commands
    print_info "Linking Claude Code commands..."
    if [ -L "$HOME/.claude/commands" ]; then
        rm "$HOME/.claude/commands"
    elif [ -d "$HOME/.claude/commands" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.claude/commands" "$HOME/.claude/commands.backup.$TIMESTAMP"
        print_warning "Backed up existing commands to commands.backup.$TIMESTAMP"
    fi

    ln -s "$DOTFILES_DIR/claude/commands" "$HOME/.claude/commands"
    print_success "Claude Code commands linked"

    # Note about authentication
    print_info "Note: Run 'claude auth login' to configure Claude Code authentication when ready"

    # Link Claude Code agents
    print_info "Linking Claude Code agents..."
    if [ -L "$HOME/.claude/agents" ]; then
        rm "$HOME/.claude/agents"
    elif [ -d "$HOME/.claude/agents" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.claude/agents" "$HOME/.claude/agents.backup.$TIMESTAMP"
        print_warning "Backed up existing agents to agents.backup.$TIMESTAMP"
    fi

    ln -s "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"
    print_success "Claude Code agents linked"

    # Link Claude Code settings
    print_info "Linking Claude Code settings..."
    if [ -f "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup.$TIMESTAMP"
        print_warning "Backed up existing settings to settings.json.backup.$TIMESTAMP"
    fi

    # Remove existing symlink if it exists
    if [ -L "$HOME/.claude/settings.json" ]; then
        rm "$HOME/.claude/settings.json"
    fi

    if [ -f "$DOTFILES_DIR/claude/settings.json" ]; then
        ln -s "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
        print_success "Claude Code settings linked"
    else
        print_info "No settings.json found in dotfiles (skipping)"
    fi

    # ===========================
    # OpenCode CLI Configuration
    # ===========================

    print_header "Setting up OpenCode CLI"

    # Install OpenCode if not already installed
    if ! command -v opencode &> /dev/null; then
        print_info "Installing OpenCode CLI..."
        curl -fsSL https://opencode.ai/install | bash

        # Add OpenCode to PATH for this session
        export PATH="$HOME/.local/bin:$PATH"

        print_success "OpenCode CLI installed"
    else
        print_success "OpenCode CLI is already installed"
    fi

    # Create .config/opencode directory if it doesn't exist
    if [ ! -d "$HOME/.config/opencode" ]; then
        print_info "Creating ~/.config/opencode directory..."
        mkdir -p "$HOME/.config/opencode"
        print_success "Created ~/.config/opencode directory"
    fi

    # Link OpenCode commands
    print_info "Linking OpenCode commands..."
    if [ -L "$HOME/.config/opencode/command" ]; then
        rm "$HOME/.config/opencode/command"
    elif [ -d "$HOME/.config/opencode/command" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.config/opencode/command" "$HOME/.config/opencode/command.backup.$TIMESTAMP"
        print_warning "Backed up existing commands to command.backup.$TIMESTAMP"
    fi

    ln -s "$DOTFILES_DIR/opencode/commands" "$HOME/.config/opencode/command"
    print_success "OpenCode commands linked"

    # Link shared AGENTS.md
    print_info "Linking shared AGENTS.md for OpenCode..."
    if [ -f "$HOME/.config/opencode/AGENTS.md" ] && [ ! -L "$HOME/.config/opencode/AGENTS.md" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$HOME/.config/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md.backup.$TIMESTAMP"
        print_warning "Backed up existing AGENTS.md to AGENTS.md.backup.$TIMESTAMP"
    fi

    if [ -L "$HOME/.config/opencode/AGENTS.md" ]; then
        rm "$HOME/.config/opencode/AGENTS.md"
    fi

    ln -s "$DOTFILES_DIR/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
    print_success "Shared AGENTS.md linked"

    # Note about authentication
    print_info "Note: Run 'opencode auth login' to configure API keys when ready"

    # ===========================
    # GitHub Copilot CLI Configuration
    # ===========================

    print_header "Setting up GitHub Copilot CLI"

    # Check Node.js version requirement (v22 or higher)
    if command -v node &> /dev/null; then
        NODE_MAJOR_VERSION=$(node --version | cut -d'.' -f1 | sed 's/v//')
        if [ "$NODE_MAJOR_VERSION" -ge 22 ]; then
            # Install GitHub Copilot CLI if not already installed
            if ! command -v copilot &> /dev/null; then
                print_info "Installing GitHub Copilot CLI..."
                npm install -g @github/copilot
                print_success "GitHub Copilot CLI installed"
            else
                print_success "GitHub Copilot CLI is already installed"
            fi
        else
            print_warning "Node.js v22+ required for GitHub Copilot CLI (current: v$NODE_MAJOR_VERSION)"
            print_info "Skipping GitHub Copilot CLI installation. Run 'fnm install 22 && fnm use 22' to upgrade."
        fi
    else
        print_warning "Node.js not found - skipping GitHub Copilot CLI installation"
    fi

    # Note about authentication
    print_info "Note: Run 'copilot' and use '/login' command to authenticate with GitHub"
    print_info "      Requires active GitHub Copilot subscription"
else
    print_info "Skipping AI coding agents installation."
fi

# ===========================
# Git Worktree Manager (wtp)
# ===========================

print_header "Setting up wtp (git worktree manager)"

# Install wtp based on platform
if [ "$OS" == "macos" ]; then
    if ! command -v wtp &> /dev/null; then
        print_info "Installing wtp via Homebrew..."
        brew tap satococoa/tap
        brew install satococoa/tap/wtp
        print_success "wtp installed"
    else
        print_success "wtp is already installed"
    fi
elif [ "$OS" == "ubuntu" ]; then
    if ! command -v wtp &> /dev/null; then
        print_info "Installing wtp (downloading latest release)..."

        # Detect architecture
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            WTP_ARCH="x86_64"
        elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            WTP_ARCH="arm64"
        else
            print_error "Unsupported architecture: $ARCH"
            print_info "Please install wtp manually from: https://github.com/satococoa/wtp/releases"
            exit 1
        fi

        # Download latest release
        WTP_VERSION=$(curl -s https://api.github.com/repos/satococoa/wtp/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
        WTP_VERSION_NUM=$(echo "$WTP_VERSION" | sed 's/^v//')
        WTP_URL="https://github.com/satococoa/wtp/releases/download/${WTP_VERSION}/wtp_${WTP_VERSION_NUM}_Linux_${WTP_ARCH}.tar.gz"

        # Create temp directory and download
        TMP_DIR=$(mktemp -d)
        cd "$TMP_DIR"
        curl -sL "$WTP_URL" -o wtp.tar.gz
        tar -xzf wtp.tar.gz

        # Move to ~/.local/bin
        mkdir -p "$HOME/.local/bin"
        mv wtp "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/wtp"

        # Cleanup
        cd - > /dev/null
        rm -rf "$TMP_DIR"

        print_success "wtp installed to ~/.local/bin/wtp"
    else
        print_success "wtp is already installed"
    fi
fi

# Add shell completion hint
print_info "Note: Add wtp shell completions to your shell config if desired:"
print_info "  Bash: eval \"\$(wtp completion bash)\""
print_info "  Zsh:  eval \"\$(wtp completion zsh)\""
print_info "  Fish: wtp completion fish | source"

# ===========================
# AI Command Helper Script
# ===========================

print_header "Setting up AI command helper script"

# Create .local/bin directory if it doesn't exist
mkdir -p "$HOME/.local/bin"

# Link ai-commands script to PATH
if [ -L "$HOME/.local/bin/ai-commands" ]; then
    rm "$HOME/.local/bin/ai-commands"
fi

ln -sf "$DOTFILES_DIR/bin/ai-commands" "$HOME/.local/bin/ai-commands"

# Make script executable
chmod +x "$DOTFILES_DIR/bin/ai-commands"

print_success "AI command helper script installed"
print_info "  - ai-commands setup: Add command instructions to project AGENTS.md"
print_info "  - ai-commands get <name>: Retrieve command prompt content"
print_info "  - ai-commands list: Show all available commands"

# ===========================
# Git Configuration (Optional)
# ===========================

print_info "Checking git configuration..."

if [ -z "$(git config --global user.name)" ]; then
    print_warning "Git user.name not set"
    read -p "Enter your git name (or press Enter to skip): " GIT_NAME
    if [ -n "$GIT_NAME" ]; then
        git config --global user.name "$GIT_NAME"
    fi
fi

if [ -z "$(git config --global user.email)" ]; then
    print_warning "Git user.email not set"
    read -p "Enter your git email (or press Enter to skip): " GIT_EMAIL
    if [ -n "$GIT_EMAIL" ]; then
        git config --global user.email "$GIT_EMAIL"
    fi
fi

# ===========================
# Platform-Specific Notes
# ===========================

PLATFORM_NOTES=""
if [ "$OS" == "macos" ]; then
    PLATFORM_NOTES="
${BLUE}[INFO]${NC} macOS-specific notes:
  - Clipboard uses pbcopy/pbpaste (built-in)
  - If using iTerm2, enable true color support in preferences
  - Homebrew packages will auto-update with 'brew upgrade'
"
elif [ "$OS" == "ubuntu" ]; then
    PLATFORM_NOTES="
${BLUE}[INFO]${NC} Ubuntu-specific notes:
  - xclip is used for clipboard support
  - Update kickstart: cd ~/.config/nvim && git pull
  - Tmux auto-starts on SSH connections
"
fi

# ===========================
# Completion
# ===========================

echo ""
echo "=========================================="
print_success "Dotfiles installation complete!"
echo "=========================================="
echo ""
print_info "What was installed:"
echo "  ✓ Tmux with vim-style bindings"
echo "  ✓ Neovim with official kickstart.nvim"
echo "  ✓ Custom config directory (~/dotfiles/nvim/custom)"
echo "  ✓ Zsh with Oh My Zsh"
echo "  ✓ fnm (Fast Node Manager) + Node.js LTS"
echo "  ✓ Claude Code custom commands and agents"
echo "  ✓ OpenCode CLI with custom commands"
echo "  ✓ wtp (git worktree manager for parallel AI workflows)"
echo "  ✓ All required dependencies"
echo ""
print_info "Next steps:"
echo "  1. Restart your shell or run: source ~/.zshrc"
echo "  2. Start tmux: tmux"
echo "  3. Launch neovim: nvim"
echo ""
print_info "Customizing neovim:"
echo "  - Add custom plugins in: ~/dotfiles/nvim/custom/plugins/"
echo "  - Add custom config in: ~/dotfiles/nvim/custom/init.lua"
echo "  - Your customizations are tracked in your dotfiles repo"
echo "  - Update kickstart anytime: cd ~/.config/nvim && git pull"
echo ""
print_info "Quick reference:"
echo "  - Tmux prefix: Ctrl-a"
echo "  - Split panes: Ctrl-a | (vertical) or Ctrl-a - (horizontal)"
echo "  - Navigate panes: Ctrl-a h/j/k/l"
echo "  - Tmux aliases: t, ta, tn, tl, tk, td"
echo ""
print_info "AI Coding Assistants:"
echo "  - Claude Code: Custom commands in ~/.claude/commands and agents in ~/.claude/agents (auth: claude auth login)"
echo "  - OpenCode CLI: Run 'opencode' to start (auth: opencode auth login)"
echo "  - GitHub Copilot CLI: Run 'copilot' then use '/login' to authenticate"
echo ""
print_info "AI Command Helper:"
echo "  - ai-commands setup: Add command instructions to any project's AGENTS.md"
echo "  - ai-commands get <name>: Get command prompt (for AI agents without slash commands)"
echo "  - ai-commands list: Show all available commands"
echo "  - Works with Copilot CLI, Claude Code custom agents, and any tool that can run bash"
echo ""
print_info "Git Worktree Manager (wtp):"
echo "  - wtp create <name>: Create new worktree for parallel AI development"
echo "  - wtp list: List all active worktrees"
echo "  - wtp switch: Switch to a worktree interactively"
echo "  - wtp delete <name>: Remove worktree and branch"
echo "  - Use with: /worktree-create, /worktree-merge commands in AI assistants"

if [ -n "$PLATFORM_NOTES" ]; then
    echo ""
    echo -e "$PLATFORM_NOTES"
fi

echo ""
print_success "Happy coding!"
