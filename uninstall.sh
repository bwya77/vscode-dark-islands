#!/bin/bash

set -e

echo "🏝️  Islands Dark Theme Uninstaller for macOS/Linux"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🔍 Checking installation..."

# Check for VS Code settings directory
SETTINGS_DIR="$HOME/.config/Code/User"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
fi

SETTINGS_FILE="$SETTINGS_DIR/settings.json"
BACKUP_FILE="$SETTINGS_DIR/settings.json.backup"

echo ""
echo "📦 Step 1: Removing Islands Dark theme extension..."
EXT_DIR="$HOME/.vscode/extensions/bwya77.islands-dark-1.0.0"

if [ -d "$EXT_DIR" ]; then
    rm -rf "$EXT_DIR"
    echo -e "${GREEN}✓ Theme extension removed from $EXT_DIR${NC}"
else
    echo -e "${YELLOW}⚠️  Theme extension not found (may already be uninstalled)${NC}"
fi

echo ""
echo "⚙️  Step 2: Restoring VS Code settings..."

if [ -f "$BACKUP_FILE" ]; then
    echo "   Found backup at: $BACKUP_FILE"
    echo "   Restoring to: $SETTINGS_FILE"

    # Backup current settings before restoring (just in case)
    if [ -f "$SETTINGS_FILE" ]; then
        cp "$SETTINGS_FILE" "$SETTINGS_FILE.pre-uninstall"
        echo -e "${YELLOW}   Current settings backed up to settings.json.pre-uninstall${NC}"
    fi

    # Restore the backup
    cp "$BACKUP_FILE" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Settings restored from backup${NC}"

    # Optionally remove the backup file
    read -p "   Remove the backup file? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$BACKUP_FILE"
        echo -e "${GREEN}✓ Backup file removed${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No backup file found at $BACKUP_FILE${NC}"
    echo "   Cannot restore previous settings automatically."
    echo "   If you have a manual backup, you can restore it yourself."
fi

echo ""
echo "🔤 Step 3: Font removal..."
echo -e "${YELLOW}⚠️  Note: Fonts are not automatically removed${NC}"
echo "   The Bear Sans UI fonts were installed system-wide and may be used by other applications."
echo "   If you want to remove them manually:"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   - Open Font Book application"
    echo "   - Search for 'Bear Sans UI'"
    echo "   - Select and delete the fonts if desired"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "   - Remove .otf files from $HOME/.local/share/fonts/"
    echo "   - Run: fc-cache -f"
fi

echo ""
echo "🔧 Step 4: Custom UI Style extension..."
echo -e "${YELLOW}⚠️  Note: Custom UI Style extension is not automatically uninstalled${NC}"
echo "   If you want to remove it:"
echo "   - Run: code --uninstall-extension subframe7536.custom-ui-style"
echo "   - Or uninstall it from VS Code Extensions panel"

# Remove first run flag
FIRST_RUN_FILE="$SCRIPT_DIR/.islands_dark_first_run"
if [ -f "$FIRST_RUN_FILE" ]; then
    rm "$FIRST_RUN_FILE"
fi

echo ""
echo "🎉 Uninstallation complete!"
echo ""
echo "   VS Code will now reload to apply the changes."
echo ""

# Reload VS Code
if command -v code &> /dev/null; then
    echo "   Reloading VS Code..."
    code --reload-window 2>/dev/null || code . 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}Done! 🏝️${NC}"
echo ""
echo "Thank you for trying Islands Dark theme!"
