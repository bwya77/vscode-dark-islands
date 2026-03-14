#!/bin/bash

set -e

echo "🏝️  Islands Dark Theme Uninstaller for macOS/Linux"
echo "==================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if code command is available
if ! command -v code &> /dev/null; then
    echo -e "${RED}❌ Error: VS Code CLI (code) not found!${NC}"
    echo "Please install VS Code and make sure 'code' command is in your PATH."
    echo "You can do this by:"
    echo "  1. Open VS Code"
    echo "  2. Press Cmd+Shift+P (macOS) or Ctrl+Shift+P (Linux)"
    echo "  3. Type 'Shell Command: Install code command in PATH'"
    exit 1
fi

echo -e "${GREEN}✓ VS Code CLI found${NC}"

# Step 1: Restore old settings
echo "⚙️  Step 1: Restoring VS Code settings..."
SETTINGS_DIR="$HOME/.config/Code/User"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
fi

SETTINGS_FILE="$SETTINGS_DIR/settings.json"
BACKUP_FILE="$SETTINGS_FILE.pre-islands-dark"

if [ -f "$BACKUP_FILE" ]; then
    cp "$BACKUP_FILE" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Settings restored from backup${NC}"
    echo "   Backup file: $BACKUP_FILE"
else
    echo -e "${YELLOW}⚠️  No backup found at $BACKUP_FILE${NC}"
    echo "   You may need to manually update your VS Code settings."
fi

# Step 2: Disable Custom UI Style
echo ""
echo "🔧 Step 2: Disabling Custom UI Style..."
echo -e "${YELLOW}   Please disable Custom UI Style manually:${NC}"
echo "   1. Open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)"
echo "   2. Run 'Custom UI Style: Disable'"
echo "   3. VS Code will reload"

# Step 3: Remove theme extension
echo ""
echo "🗑️  Step 3: Removing Islands Dark theme extension..."
EXT_DIR="$HOME/.vscode/extensions/bwya77.islands-dark-1.0.0"
if [ -d "$EXT_DIR" ] || [ -L "$EXT_DIR" ]; then
    rm -rf "$EXT_DIR"
    echo -e "${GREEN}✓ Theme extension removed${NC}"
else
    echo -e "${YELLOW}⚠️  Extension directory not found (may already be removed)${NC}"
fi

# Step 4: Uninstall extension via VS Code CLI
echo ""
echo "📋 Step 4: Uninstalling extension from VS Code..."
if code --uninstall-extension bwya77.islands-dark --force 2>/dev/null; then
    echo -e "${GREEN}✓ Extension uninstalled via VS Code CLI${NC}"
else
    echo -e "${YELLOW}⚠️  Extension not installed (or already removed)${NC}"
fi

# Step 5: Change theme
echo ""
echo "🎨 Step 5: Change your color theme..."
echo "   1. Open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)"
echo "   2. Search for 'Preferences: Color Theme'"
echo "   3. Select your preferred theme"

echo ""
echo -e "${GREEN}✓ Islands Dark has been uninstalled!${NC}"
echo ""
echo "   Reload VS Code to complete the process."
echo ""
