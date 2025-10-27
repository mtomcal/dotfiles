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
install_package "neovim" "neovim"
install_package "ripgrep" "ripgrep"
install_package "zsh" "zsh"

# Platform-specific packages
if [ "$OS" == "ubuntu" ]; then
    install_package "build-essential"
    install_package "fd-find"
    install_package "xclip"
elif [ "$OS" == "macos" ]; then
    install_package "gcc" "gcc"
    install_package "fd" "fd"
    # macOS uses pbcopy/pbpaste built-in, no xclip needed
fi

# ===========================
# Install Latest Neovim (Ubuntu only)
# ===========================

if [ "$OS" == "ubuntu" ]; then
    print_info "Checking Neovim version..."
    NVIM_VERSION=$(nvim --version | head -n1 | grep -oP 'v\K[0-9]+\.[0-9]+')

    if [[ $(echo "$NVIM_VERSION < 0.11" | bc -l 2>/dev/null || echo "1") -eq 1 ]]; then
        print_warning "Neovim version is $NVIM_VERSION (recommended: 0.11+)"
        read -p "Would you like to upgrade to the latest Neovim from neovim-ppa/unstable? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Adding neovim-ppa/unstable..."
            sudo add-apt-repository ppa:neovim-ppa/unstable -y
            sudo apt update
            sudo apt install -y neovim
            print_success "Neovim upgraded to latest version"
        fi
    else
        print_success "Neovim version is $NVIM_VERSION (meets requirements)"
    fi
elif [ "$OS" == "macos" ]; then
    print_info "Updating Neovim to latest version via Homebrew..."
    brew upgrade neovim || print_success "Neovim is already up to date"
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
nvim --headless "+Lazy! sync" +qa
print_success "Neovim plugins installed"

# ===========================
# Claude Code Configuration
# ===========================

print_header "Setting up Claude Code configuration"

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

# Link Claude Code settings
print_info "Linking Claude Code settings..."
if [ -f "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mv "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup.$TIMESTAMP"
    print_warning "Backed up existing settings to settings.json.backup.$TIMESTAMP"
fi

if [ -f "$DOTFILES_DIR/claude/settings.json" ]; then
    ln -s "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
    print_success "Claude Code settings linked"
else
    print_info "No settings.json found in dotfiles (skipping)"
fi

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

if [ -n "$PLATFORM_NOTES" ]; then
    echo ""
    echo -e "$PLATFORM_NOTES"
fi

echo ""
print_success "Happy coding!"
