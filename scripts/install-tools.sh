#!/bin/bash

# Optional tools installer for AKS + Airbyte playground
# This script installs tools that enhance the experience but aren't strictly required

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[OPTIONAL]${NC} $1"; }

echo "🛠️  Optional Tools Installer for AKS Playground"
echo "==============================================="

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
fi

print_status "Detected OS: $OS"

# k9s (Kubernetes cluster management)
if ! command -v k9s &> /dev/null; then
    print_warning "Installing k9s (Kubernetes cluster manager)..."
    if [[ "$OS" == "macos" ]]; then
        brew install k9s
    elif [[ "$OS" == "linux" ]]; then
        curl -sS https://webinstall.dev/k9s | bash
        export PATH="$HOME/.local/bin:$PATH"
    fi
    print_success "k9s installed"
else
    print_status "k9s already installed"
fi

# kubectx/kubens (context switching)
if ! command -v kubectx &> /dev/null; then
    print_warning "Installing kubectx/kubens (context switching)..."
    if [[ "$OS" == "macos" ]]; then
        brew install kubectx
    elif [[ "$OS" == "linux" ]]; then
        sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
        sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
        sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
    fi
    print_success "kubectx/kubens installed"
else
    print_status "kubectx already installed"
fi

# stern (multi-pod log tailing)
if ! command -v stern &> /dev/null; then
    print_warning "Installing stern (log tailing)..."
    if [[ "$OS" == "macos" ]]; then
        brew install stern
    elif [[ "$OS" == "linux" ]]; then
        curl -L https://github.com/stern/stern/releases/latest/download/stern_linux_amd64.tar.gz | tar xz
        sudo mv stern /usr/local/bin/
    fi
    print_success "stern installed"
else
    print_status "stern already installed"
fi

echo ""
print_success "✅ Optional tools installation complete!"
echo ""
print_status "🎯 Enhanced Commands Available:"
echo "  • k9s                    # Interactive cluster management"
echo "  • kubens airbyte         # Switch to airbyte namespace"
echo "  • stern airbyte          # Tail logs from all airbyte pods"
echo ""
print_warning "💡 These tools are optional but make Kubernetes management much easier!"
