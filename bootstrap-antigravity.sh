#!/bin/bash

set -e

# Islands Dark Theme Bootstrap Installer for Antigravity (macOS)
# One-liner: curl -fsSL https://raw.githubusercontent.com/bwya77/vscode-dark-islands/main/bootstrap-antigravity.sh | bash

echo "Islands Dark Theme Bootstrap Installer for Antigravity"
echo "======================================================="
echo ""

REPO_URL="https://github.com/bwya77/vscode-dark-islands.git"
INSTALL_DIR="$HOME/.islands-dark-antigravity-temp"

# Verify macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: Antigravity on macOS only."
    echo "For Windows, use install-antigravity.ps1 or install-antigravity.bat"
    exit 1
fi

echo "Step 1: Downloading Islands Dark..."
echo "   Repository: $REPO_URL"

rm -rf "$INSTALL_DIR"

if ! git clone "$REPO_URL" "$INSTALL_DIR" --quiet --branch main; then
    echo "Failed to download Islands Dark"
    exit 1
fi

echo "Downloaded successfully!"
echo ""

echo "Step 2: Running Antigravity installer..."
echo ""

cd "$INSTALL_DIR"
bash install-antigravity.sh

echo ""
echo "Step 3: Cleaning up..."

read -p "   Remove temporary files? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$INSTALL_DIR"
    echo "Temporary files removed"
else
    echo "   Files kept at: $INSTALL_DIR"
fi

echo ""
echo "Done!"
