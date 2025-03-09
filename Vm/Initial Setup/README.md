# Developer Environment Setup Guide

This guide helps you set up a complete developer environment with Kubernetes tools, terminal multiplexer, and a powerful text editor configuration.

## What's Included

- **Kubernetes Tools**: kubectl, k9s, and k3s for container orchestration
- **Terminal Tools**: tmux with custom configuration
- **Text Editor**: Neovim with LazyVim configuration
- **Shell Enhancements**: kubectl autocompletion and helpful aliases

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dev-environment-setup.git
   cd dev-environment-setup
   ```

2. Make the installation scripts executable:
   ```bash
   chmod +x install-x86_64.sh install-arm64.sh
   ```

3. Run the appropriate script for your architecture:

   For x86_64/AMD64 (most common):
   ```bash
   ./install-x86_64.sh
   ```

   For ARM64 (Raspberry Pi, AWS Graviton, etc.):
   ```bash
   ./install-arm64.sh
   ```

4. Restart your shell or run:
   ```bash
   source ~/.bashrc
   ```

## Manual Installation

If you prefer to install components individually or if the script fails, follow these step-by-step instructions.

### System Update

```bash
sudo apt update
sudo apt upgrade -y
```

### Install Dependencies

```bash
sudo apt install -y git curl wget unzip tar gzip build-essential make
```

### Tmux Setup

1. Install tmux:
   ```bash
   sudo apt install -y tmux
   ```

2. Create tmux configuration file:
   ```bash
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
   ```

### Kubectl Setup

For AMD64/x86_64:
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

For ARM64:
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### K9s Setup

For AMD64/x86_64:
```bash
curl -L https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz -o k9s.tar.gz
tar -xzf k9s.tar.gz
chmod +x k9s
sudo mv k9s /usr/local/bin/
rm k9s.tar.gz
```

For ARM64:
```bash
curl -L https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_arm64.tar.gz -o k9s.tar.gz
tar -xzf k9s.tar.gz
chmod +x k9s
sudo mv k9s /usr/local/bin/
rm k9s.tar.gz
```

### K3s Setup

```bash
curl -sfL https://get.k3s.io | sh -
mkdir -p ~/.kube
sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

### Shell Aliases and Completions

Add to your ~/.bashrc:

```bash
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

source ~/.bashrc
```

### Neovim with LazyVim Setup

1. Install Neovim:
   ```bash
   # For Ubuntu/Debian
   sudo add-apt-repository ppa:neovim-ppa/unstable
   sudo apt update
   sudo apt install -y neovim
   
   # For other distributions or if the above fails
   # Download and install manually
   # Visit https://github.com/neovim/neovim/releases
   ```

2. Install dependencies:
   ```bash
   sudo apt install -y ripgrep fd-find nodejs npm
   ```

3. Install Nerd Font (for icons):
   ```bash
   mkdir -p ~/.local/share/fonts
   cd ~/.local/share/fonts
   curl -fLo "JetBrainsMono NF Regular.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf
   fc-cache -f -v
   ```

4. Install LazyVim:
   ```bash
   # Backup existing Neovim configuration (if any)
   [ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.backup
   [ -d ~/.local/share/nvim ] && mv ~/.local/share/nvim ~/.local/share/nvim.backup
   [ -d ~/.local/state/nvim ] && mv ~/.local/state/nvim ~/.local/state/nvim.backup
   [ -d ~/.cache/nvim ] && mv ~/.cache/nvim ~/.cache/nvim.backup

   # Clone LazyVim starter configuration
   git clone https://github.com/LazyVim/starter ~/.config/nvim
   rm -rf ~/.config/nvim/.git
   ```

## Usage Guides

### Tmux Basics

1. Start a new tmux session:
   ```bash
   tmux
   ```

2. Tmux prefix key: `Ctrl+b`

3. Common tmux commands (press prefix first, then the key):
   - `c`: Create a new window
   - `n`: Next window
   - `p`: Previous window
   - `%`: Split vertically
   - `"`: Split horizontally
   - `[`: Enter copy mode
   - `]`: Paste from buffer
   - Arrow keys: Navigate between panes
   - `d`: Detach from session

4. Copy mode (after pressing `Ctrl+b` then `[`):
   - Navigate with arrow keys
   - `Space` to start selection
   - `Enter` to copy selection
   - Use `q` to exit copy mode

5. Reattach to a detached session:
   ```bash
   tmux attach
   ```

6. List sessions:
   ```bash
   tmux ls
   ```

### kubectl and k9s

1. Get cluster status:
   ```bash
   kubectl cluster-info
   ```

2. List resources:
   ```bash
   k get pods
   k get nodes
   k get deployments
   ```

3. Launch k9s:
   ```bash
   k9s
   ```

4. k9s navigation:
   - `0`: View all namespaces
   - `:`: Command mode (type resource name)
   - `/`: Filter resources
   - `d`: Describe resource
   - `e`: Edit resource
   - `l`: View logs
   - `Esc`: Back/Cancel

### Neovim with LazyVim

1. Open a file:
   ```bash
   nvim file.txt
   ```

2. Basic commands:
   - `i`: Enter insert mode
   - `Esc`: Return to normal mode
   - `:w`: Save
   - `:q`: Quit
   - `:wq`: Save and quit

3. LazyVim specific keybindings:
   - `Space`: Open command menu
   - `Space + f`: Find files
   - `Space + /`: Search in files
   - `Space + e`: File explorer
   - `Space + q`: Quit menu
   - `Ctrl+h/j/k/l`: Navigate between splits

4. File Explorer (Neo-tree):
   - `j/k`: Move up/down
   - `Enter`: Open file
   - `-`: Go up a directory
   - `a`: Create file/directory
   - `d`: Delete file/directory
   - `r`: Rename file/directory
   - `y`: Copy file path
   - `x`: Cut file
   - `p`: Paste file

5. Terminal:
   - `Ctrl+\`: Open terminal
   - `i`: Interact with terminal
   - `Esc`: Exit terminal mode

## Troubleshooting

### Kubernetes Connection Issues

If kubectl cannot connect to your cluster:

1. Check if k3s is running:
   ```bash
   sudo systemctl status k3s
   ```

2. Restart k3s if needed:
   ```bash
   sudo systemctl restart k3s
   ```

3. Verify kubeconfig:
   ```bash
   kubectl config view
   ```

4. Recreate kubeconfig if needed:
   ```bash
   sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
   sudo chown $USER:$USER ~/.kube/config
   ```

### Neovim Issues

1. If plugins aren't loading:
   ```bash
   rm -rf ~/.local/share/nvim
   rm -rf ~/.cache/nvim
   nvim
   ```

2. Check plugin status in Neovim:
   ```
   :checkhealth
   ```

### Font Issues

If icons in Neovim/LazyVim don't display correctly:
1. Make sure you installed the Nerd Font
2. Configure your terminal to use the Nerd Font