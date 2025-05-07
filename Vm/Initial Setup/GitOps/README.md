## Additional Tools Installation

This section covers the installation of Docker, Kind (Kubernetes in Docker), and Flux CD for GitOps workflows.

### Docker Installation

1. Install Docker:
   ```bash
   sudo apt-get update
   sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
   sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io
   sudo usermod -aG docker ${USER}
   newgrp docker
   ```

2. Verify Docker installation:
   ```bash
   docker version
   ```

### Kind (Kubernetes in Docker) Installation

1. Install Kind:
   ```bash
   wget https://github.com/kubernetes-sigs/kind/releases/download/v0.18.0/kind-linux-amd64
   sudo mv kind-linux-amd64 /usr/local/bin/kind
   sudo chmod +x /usr/local/bin/kind
   ```

2. Verify Kind installation:
   ```bash
   kind version
   ```

3. Create a cluster configuration file:
   ```bash
   cat > cluster.yaml << 'EOF'
   kind: Cluster
   apiVersion: kind.x-k8s.io/v1alpha4
   nodes:
   - role: control-plane
     kubeadmConfigPatches:
     - |
       kind: InitConfiguration
       nodeRegistration:
         kubeletExtraArgs:
           node-labels: "ingress-ready=true"
     extraPortMappings:
     - containerPort: 80
       hostPort: 80
       protocol: TCP
     - containerPort: 443
       hostPort: 443
       protocol: TCP
   EOF
   ```

4. Create a Kind cluster:
   ```bash
   kind create cluster --config=cluster.yaml
   ```

5. Verify the cluster:
   ```bash
   kubectl cluster-info --context kind-kind
   ```

### Flux CD Installation

1. Install Flux CD:
   ```bash
   # For Ubuntu/Debian
   curl -s https://fluxcd.io/install.sh | sudo bash

   # Alternatively, if you have Homebrew:
   # brew install fluxcd/tap/flux
   ```

2. Create a GitLab personal access token:
   - Go to GitLab.com → Profile picture → Preferences → Access Tokens
   - Create a token with API permissions
   - Name it "flux" or something similar
   - Copy the token value

3. Set up Flux repository structure:
   ```bash
   # Create repository structure
   mkdir -p myfluxrepo/clusters/my-cluster/flux-system
   cd myfluxrepo/clusters/my-cluster/flux-system
   
   # Create necessary files
   touch gotk-components.yaml gotk-sync.yaml kustomization.yaml
   
   # Add Kustomization configuration
   cat > kustomization.yaml << 'EOF'
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
   - gotk-components.yaml
   - gotk-sync.yaml
   EOF
   ```

4. Bootstrap Flux with GitLab:
   ```bash
   # Export GitLab token
   export GITLAB_TOKEN=your_gitlab_token_here
   
   # Bootstrap Flux
   flux bootstrap gitlab --owner=your_gitlab_username --repository=myfluxrepo --branch=main --path=clusters/my-cluster --token-auth --personal
   ```

5. Verify Flux installation:
   ```bash
   kubectl get gitrepo -n flux-system
   kubectl get secrets -n flux-system
   ```

### Deploying Sample Application with Flux

1. Create a GitRepository manifest for podinfo:
   ```bash
   cat > podinfo-repo.yaml << 'EOF'
   apiVersion: source.toolkit.fluxcd.io/v1
   kind: GitRepository
   metadata:
     name: podinfo
     namespace: flux-system
   spec:
     interval: 30s
     ref:
       branch: master
     url: https://github.com/stefanprodan/podinfo
   EOF
   ```

2. Create a Kustomization manifest for podinfo:
   ```bash
   cat > podinfo-kustomization.yaml << 'EOF'
   apiVersion: kustomize.toolkit.fluxcd.io/v1
   kind: Kustomization
   metadata:
     name: podinfo
     namespace: flux-system
   spec:
     interval: 5m0s
     path: ./kustomize
     prune: true
     sourceRef:
       kind: GitRepository
       name: podinfo
     targetNamespace: default
   EOF
   ```

3. Commit and push to your repository:
   ```bash
   git add -A
   git commit -m "Adds the podinfo repo and kustomization"
   git push
   ```

4. Monitor the synchronization:
   ```bash
   flux get kustomizations --watch
   ```

5. Access the deployment:
   ```bash
   kubectl get pods
   kubectl port-forward [podinfo-pod-name] 9898:9898 --address 0.0.0.0
   ```

## Prerequisites for Installation

Before running the installation scripts, ensure:

- Ubuntu or Debian-based Linux distribution
- Sudo privileges
- Internet connection for downloading packages

## Combined Installation Script

Below is a modified version of the installation script that includes Docker, Kind, and Flux CD:

```bash
#!/bin/bash

# Complete Developer Environment Installation Script (x86_64/AMD64)
# ================================================================
# This script installs Docker, Kubernetes tools (kubectl, k9s, k3s, kind),
# Flux CD, tmux, and Neovim with LazyVim

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

# Detect architecture to confirm x86_64
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" ]]; then
    error "This script is intended for x86_64/AMD64 architecture"
    error "Current architecture: $ARCH"
    error "Please use the ARM64 script instead"
    exit 1
fi

# Update system packages
log "Updating system packages..."
sudo apt update || warning "Unable to update package lists. Continuing anyway..."
sudo apt upgrade -y || warning "Unable to upgrade packages. Continuing anyway..."

# Install dependencies
log "Installing dependencies..."
sudo apt install -y git curl wget unzip tar gzip build-essential make apt-transport-https ca-certificates gnupg-agent software-properties-common || warning "Some dependencies failed to install"

# Install Docker
log "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker ${USER}
# Note: The effect of this command will only be available after a new login session
# We'll remind the user about this at the end
success "Docker installed"

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
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client || error "kubectl installation failed"
success "kubectl installed"

# Install k9s
log "Installing k9s..."
curl -L https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz -o k9s.tar.gz
tar -xzf k9s.tar.gz
chmod +x k9s
sudo mv k9s /usr/local/bin/
rm k9s.tar.gz
k9s version || warning "k9s installation may have issues"
success "k9s installed"

# Install Kind (Kubernetes in Docker)
log "Installing Kind..."
curl -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/v0.18.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind version || warning "Kind installation may have issues"
success "Kind installed"

# Create Kind configuration file
log "Creating Kind cluster configuration..."
cat > ./cluster.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
success "Kind configuration created"

# Install Flux CD
log "Installing Flux CD..."
curl -s https://fluxcd.io/install.sh | sudo bash
flux --version || warning "Flux CD installation may have issues"
success "Flux CD installed"

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

# Flux completion
if command -v flux >/dev/null 2>&1; then
  source <(flux completion bash)
fi
EOF
success "Shell configuration updated"

# Install Neovim
log "Installing Neovim..."
sudo add-apt-repository ppa:neovim-ppa/unstable -y || warning "Unable to add Neovim PPA"
sudo apt update
sudo apt install -y neovim || {
    warning "Neovim installation from PPA failed, trying alternative method"
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
    tar -xzf nvim-linux64.tar.gz
    sudo mv nvim-linux64 /opt/
    sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux64.tar.gz
}
nvim --version || error "Neovim installation failed"
success "Neovim installed"

# Install Neovim dependencies
log "Installing Neovim dependencies..."
sudo apt install -y ripgrep fd-find nodejs npm || warning "Some Neovim dependencies failed to install"

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
- Docker Engine
- kubectl, k9s, k3s, and Kind for Kubernetes
- Flux CD for GitOps
- tmux with custom configuration
- Neovim with LazyVim
- Shell aliases and completions

${BLUE}Next steps:${NC}
1. Log out and log back in to apply Docker group membership
   Or run: newgrp docker
2. Start tmux: tmux
3. Create a Kind cluster: kind create cluster --config=cluster.yaml
4. Try kubectl: k get nodes
5. Try k9s: k9s
6. Try Neovim: nvim
7. Set up Flux with GitLab or GitHub

${YELLOW}NOTE:${NC} Your terminal font should be set to a Nerd Font
for icons to display correctly in Neovim.

${GREEN}Enjoy your new developer environment!${NC}
EOF
```

You can save this as `install-complete.sh` and make it executable with `chmod +x install-complete.sh`.
