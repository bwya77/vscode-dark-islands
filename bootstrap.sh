#!/bin/bash

set -e

# Islands Dark Theme Bootstrap Installer
# One-liner: curl -fsSL https://raw.githubusercontent.com/bwya77/vscode-dark-islands/main/bootstrap.sh | bash

echo "🏝️  Islands Dark Theme Bootstrap Installer"
echo "=========================================="
echo ""

REPO_URL="https://github.com/bwya77/vscode-dark-islands.git"
INSTALL_DIR="$HOME/.islands-dark-temp"
INSTALL_ARGS=("$@")

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
else
    OS="Linux"
fi

echo "📥 Step 1: Downloading Islands Dark..."
echo "   Repository: $REPO_URL"

# Remove old temp directory if exists
rm -rf "$INSTALL_DIR"


# Clone repository
BRANCH="main"
if ! git clone "$REPO_URL" "$INSTALL_DIR" --quiet --branch "$BRANCH"; then
    echo "❌ Failed to download Islands Dark"
    exit 1
fi

echo "✓ Downloaded successfully!"
echo ""

echo "🚀 Step 2: Running installer..."
echo ""

# Run appropriate installer
if [[ "$OS" == "macOS" ]] || [[ "$OS" == "Linux" ]]; then
    cd "$INSTALL_DIR"
    bash install.sh "${INSTALL_ARGS[@]}"
else
    echo "⚠️  Automatic installation not supported for this OS"
    echo "   Please manually run: cd $INSTALL_DIR && ./install.sh [--vscode|--vscodium]"
    exit 1
fi

# Cleanup (optional - keeps the temp directory)
echo ""
echo "🧹 Step 3: Cleaning up..."
read -p "   Remove temporary files? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$INSTALL_DIR"
    echo "✓ Temporary files removed"
else
    echo "   Files kept at: $INSTALL_DIR"
fi

echo ""
echo -e "🎉 Done! Enjoy your Islands Dark theme!"
