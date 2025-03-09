#!/bin/bash

# Developer Environment Installation Script (ARM64)
# ================================================
# This script installs Kubernetes tools, tmux, and Neovim with LazyVim
# For ARM64 architecture (Raspberry Pi, AWS Graviton, Oracle ARM, etc.)

set -e # Exit immediately if a command exits with a non-zero status

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Success function
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Warning function
warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Error function
error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    error "Please do not run this script as root"
    exit 1
fi

# Detect architecture to confirm ARM64
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    error "This script is intended for ARM64 architecture"
    error "Current architecture: $ARCH"
    error "Please use the x86_64 script instead"
    exit 1
fi

# Update system packages
log "Updating system packages..."
sudo apt update || warning "Unable to update package lists. Continuing anyway..."
sudo apt upgrade -y || warning "Unable to upgrade packages. Continuing anyway..."

# Install dependencies
log "Installing dependencies..."
sudo apt install -y git curl wget unzip tar gzip build-essential make || warning "Some dependencies failed to install"

# Install tmux
log "Installing tmux..."
sudo apt install -y tmux || error "Failed to install tmux"

# Configure tmux
log "Configuring tmux..."
cat > ~/.tmux.conf << 'EOF'
# Set history limit
set-option -g history-limit 25000

# Enable mouse support
set -g mouse on

# For copy mode
set -g escape-time 10
set-option -g focus-events on

# Set vi keys for copy mode
set-window-option -g mode-keys vi

# Status bar configuration
set -g status-right "#(hostname)"
set -g status-style "fg=#66c5c4"
set -g status-left-style "fg=#928374"
set -g status-bg default
set -g status-position top
set -g status-interval 1
set -g status-left ""

# Count panes from 1 instead of 0
set -g base-index 1
set -g pane-base-index 1

# Reload config with r
bind-key r source-file ~/.tmux.conf

# Set terminal colors
set-option -g default-terminal "screen-256color"
EOF
success "tmux configuration created"

# Install kubectl
log "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client || error "kubectl installation failed"
success "kubectl installed"

# Install k9s
log "Installing k9s..."
curl -L https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_arm64.tar.gz -o k9s.tar.gz
tar -xzf k9s.tar.gz
chmod +x k9s
sudo mv k9s /usr/local/bin/
rm k9s.tar.gz
k9s version || warning "k9s installation may have issues"
success "k9s installed"

# Install k3s
log "Installing k3s..."
curl -sfL https://get.k3s.io | sh -
mkdir -p ~/.kube
sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config
success "k3s installed and configured"

# Configure shell aliases and completions
log "Setting up shell aliases and completions..."
cat >> ~/.bashrc << 'EOF'

# Kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias k9='k9s'

# Functions for context and namespace switching
kc() {
  kubectl config use-context $1
}

kn() {
  kubectl config set-context --current --namespace=$1
}

# Enable kubectl bash completion
source <(kubectl completion bash)
complete -F __start_kubectl k

# Optional: Enable k9s bash completion
if command -v k9s >/dev/null 2>&1; then
  source <(k9s completion bash)
fi
EOF
success "Shell configuration updated"

# Install Neovim
log "Installing Neovim..."
if sudo add-apt-repository ppa:neovim-ppa/unstable -y; then
    sudo apt update
    sudo apt install -y neovim || {
        warning "Neovim installation from PPA failed, trying alternative method"
        # For ARM64, we need to build from source if the PPA fails
        sudo apt install -y ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl
        git clone https://github.com/neovim/neovim
        cd neovim
        git checkout stable
        make CMAKE_BUILD_TYPE=RelWithDebInfo
        sudo make install
        cd ..
        rm -rf neovim
    }
else
    warning "Neovim PPA not available, trying to install via apt"
    sudo apt install -y neovim || {
        warning "Neovim installation via apt failed, building from source"
        sudo apt install -y ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl
        git clone https://github.com/neovim/neovim
        cd neovim
        git checkout stable
        make CMAKE_BUILD_TYPE=RelWithDebInfo
        sudo make install
        cd ..
        rm -rf neovim
    }
fi
nvim --version || error "Neovim installation failed"
success "Neovim installed"

# Install Neovim dependencies
log "Installing Neovim dependencies..."
sudo apt install -y ripgrep || warning "Failed to install ripgrep"

# Install fd-find
sudo apt install -y fd-find || warning "Failed to install fd-find"
mkdir -p ~/.local/bin
ln -sf $(which fdfind) ~/.local/bin/fd

# Install Node.js
log "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || {
    warning "NodeSource setup failed, installing from default repos"
    sudo apt install -y nodejs npm
}
sudo apt install -y nodejs || warning "Node.js installation failed"

# Install Nerd Font
log "Installing Nerd Font..."
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -fLo "JetBrainsMono NF Regular.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf
fc-cache -f -v
success "Nerd Font installed"

# Install LazyVim
log "Installing LazyVim..."
# Backup existing Neovim configuration
[ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.backup
[ -d ~/.local/share/nvim ] && mv ~/.local/share/nvim ~/.local/share/nvim.backup
[ -d ~/.local/state/nvim ] && mv ~/.local/state/nvim ~/.local/state/nvim.backup
[ -d ~/.cache/nvim ] && mv ~/.cache/nvim ~/.cache/nvim.backup

# Clone LazyVim starter configuration
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
success "LazyVim installed"

# Final message
cat << EOF
${GREEN}
======================================================
        Developer Environment Setup Complete!
======================================================
${NC}
${BLUE}What's installed:${NC}
- tmux with custom configuration
- kubectl, k9s, and k3s for Kubernetes
- Neovim with LazyVim
- Shell aliases and completions

${BLUE}Next steps:${NC}
1. Restart your shell: exec bash
2. Start tmux: tmux
3. Enter tmux copy mode: Ctrl+b then [
4. Try kubectl: k get nodes
5. Try k9s: k9s
6. Try Neovim: nvim

${YELLOW}NOTE:${NC} Your terminal font should be set to a Nerd Font
for icons to display correctly in Neovim.

${GREEN}Enjoy your new developer environment!${NC}
EOF