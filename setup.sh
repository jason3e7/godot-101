#!/bin/bash
# Godot Engine 4 setup script for Ubuntu/Debian (snap-based)

set -e

echo "=== Godot Engine 4 Setup ==="

# Check OS
if ! command -v snap &>/dev/null; then
    echo "Error: snap is not installed. Please install snapd first."
    echo "  sudo apt update && sudo apt install snapd"
    exit 1
fi

# Check if already installed
if command -v godot-4 &>/dev/null; then
    echo "Godot 4 is already installed: $(godot-4 --version)"
    exit 0
fi

# Install Godot 4 via snap
echo "Installing Godot 4 via snap..."
sudo snap install godot-4

# Verify installation
VERSION=$(godot-4 --version 2>/dev/null || /snap/bin/godot-4 --version)
echo ""
echo "=== Installation complete ==="
echo "Godot version: $VERSION"
echo "Run with: godot-4"
