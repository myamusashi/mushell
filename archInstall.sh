#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
INSTALL_DIR="$HOME/.local/share/quickshell"
BIN_DIR="$HOME/.local/bin"
FONT_DIR="$HOME/.local/share/fonts"
BUILD_DIR="/tmp/quickshell-build"

echo_info "Creating directories..."
mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$FONT_DIR" "$BUILD_DIR"

if ! command -v pacman &> /dev/null; then
    echo_error "This script is designed for Arch Linux and derivatives"
    exit 1
fi

echo_info "Installing system dependencies..."
sudo pacman -S --needed --noconfirm \
    base-devel \
    git \
    go \
    qt6-base \
    qt6-declarative \
    qt6-svg \
    qt6-graphs \
    cmake \
    extra-cmake-modules \
    findutils \
    grep \
    sed \
    gawk \
    util-linux \
    networkmanager \
    libnotify \
    wl-clipboard \
    ffmpeg \
    foot \
    polkit \
    hyprland

if ! command -v yay &> /dev/null; then
    echo_info "Installing yay AUR helper..."
    cd "$BUILD_DIR"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
fi

echo_info "Installing AUR packages..."
yay -S --needed --noconfirm \
    quickshell-git \
    matugen-bin \
    playerctl \
    wl-screenrec

echo_info "Building keystate-bin..."
cd "$BUILD_DIR"
if [ -f "Assets/keystate.go" ]; then
    go build -o keystate-bin Assets/keystate.go
    install -Dm755 keystate-bin "$BIN_DIR/keystate-bin"
else
    echo_warn "keystate.go not found in Assets/, skipping..."
fi

echo_info "Installing app2unit..."
cd "$BUILD_DIR"
git clone https://github.com/Vladimir-csp/app2unit.git
cd app2unit
git checkout v1.0.3
install -Dm755 app2unit "$BIN_DIR/app2unit"

echo_info "Installing Material Symbols font..."
cd "$BUILD_DIR"
git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/google/material-design-icons.git
cd material-design-icons
git sparse-checkout set variablefont
mkdir -p "$FONT_DIR/truetype"
cp variablefont/*.ttf "$FONT_DIR/truetype/"
fc-cache -f

echo_info "Cloning rounded-polygon-qmljs submodule..."
cd "$BUILD_DIR"
git clone https://github.com/end-4/rounded-polygon-qmljs.git
ROUNDED_POLYGON_DIR="$BUILD_DIR/rounded-polygon-qmljs"

echo_info "Installing quickshell configuration..."
cd "$(dirname "$0")"
PROJECT_ROOT="$(pwd)"

rm -rf "$INSTALL_DIR"/*

cp -r "$PROJECT_ROOT"/* "$INSTALL_DIR/"

rm -rf "$INSTALL_DIR/Submodules/rounded-polygon-qmljs"
mkdir -p "$INSTALL_DIR/Submodules"
ln -sf "$ROUNDED_POLYGON_DIR" "$INSTALL_DIR/Submodules/rounded-polygon-qmljs"

echo_info "Patching shell.qml..."
sed -i "s/ShellRoot {/ShellRoot { settings.watchFiles: false/" "$INSTALL_DIR/shell.qml"

if [ -f "$BIN_DIR/keystate-bin" ]; then
    install -Dm755 "$BIN_DIR/keystate-bin" "$INSTALL_DIR/Assets/keystate-bin"
fi

echo_info "Creating wrapper script..."
cat > "$BIN_DIR/shell" << 'EOF'
#!/bin/bash

export QUICKSHELL_CONFIG_DIR="$HOME/.local/share/quickshell"
export QT_QPA_FONTDIR="$HOME/.local/share/fonts"

exec quickshell -p "$QUICKSHELL_CONFIG_DIR" "$@"
EOF

chmod +x "$BIN_DIR/shell"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo_warn "Adding $HOME/.local/bin to PATH..."
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
fi

echo_info "Cleaning up build directory..."
rm -rf "$BUILD_DIR"

echo_info "Installation complete!"
echo_info "You can now run 'shell' to start quickshell"
echo_info "Note: You may need to restart your shell or run 'source ~/.bashrc' to update PATH"
