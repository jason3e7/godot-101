#!/bin/bash
# Godot Engine 4 + 2048 dev environment setup (Ubuntu/Debian, snap-based)

set -e

echo "=== 2048 / Godot 4 Environment Setup ==="

# ── Godot 4 ──────────────────────────────────────────────────────────────────
if ! command -v snap &>/dev/null; then
    echo "Error: snapd is not installed."
    echo "  sudo apt update && sudo apt install snapd"
    exit 1
fi

if command -v godot-4 &>/dev/null || /snap/bin/godot-4 --version &>/dev/null 2>&1; then
    echo "Godot 4 already installed: $(godot-4 --version 2>/dev/null || /snap/bin/godot-4 --version)"
else
    echo "Installing Godot 4 via snap..."
    sudo snap install godot-4
    echo "Godot 4 installed: $(godot-4 --version)"
fi

# ── Xvfb (virtual framebuffer for headless / server testing) ─────────────────
if command -v Xvfb &>/dev/null; then
    echo "Xvfb already installed."
else
    echo "Installing Xvfb..."
    sudo apt-get update -qq
    sudo apt-get install -y xvfb
    echo "Xvfb installed."
fi

# ── ImageMagick (screenshot capture for visual verification) ─────────────────
if command -v import &>/dev/null; then
    echo "ImageMagick already installed."
else
    echo "Installing ImageMagick..."
    sudo apt-get install -y imagemagick
    echo "ImageMagick installed."
fi

echo ""
echo "=== Setup complete ==="
echo "  Godot  : $(godot-4 --version 2>/dev/null || /snap/bin/godot-4 --version)"
echo "  Xvfb   : $(Xvfb -version 2>&1 | head -1)"
echo "  ImageMagick : $(import -version 2>&1 | head -1)"
echo ""
echo "Run tests : ./test.sh"
echo "Run game  : DISPLAY=:99 godot-4 --path game/"
