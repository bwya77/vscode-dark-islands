#!/bin/bash

set -e


echo "🏝️  Islands Dark Theme Installer for Cursor (macOS/Linux)"
echo "========================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if cursor command is available
if ! command -v cursor &> /dev/null; then
    echo -e "${RED}❌ Error: Cursor CLI (cursor) not found!${NC}"
    echo "Please install Cursor and make sure 'cursor' command is in your PATH."
    echo "You can do this by:"
    echo "  1. Open Cursor"
    echo "  2. Press Cmd+Shift+P (macOS) or Ctrl+Shift+P (Linux)"
    echo "  3. Type 'Shell Command: Install cursor command in PATH'"
    exit 1
fi

echo -e "${GREEN}✓ Cursor CLI found${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "📦 Step 1: Installing Islands Dark theme extension..."

# Install by copying to Cursor extensions directory
EXT_DIR="$HOME/.cursor/extensions/bwya77.islands-dark-1.0.0"
rm -rf "$EXT_DIR"
mkdir -p "$EXT_DIR"
cp "$SCRIPT_DIR/package.json" "$EXT_DIR/"
cp -r "$SCRIPT_DIR/themes" "$EXT_DIR/"

if [ -d "$EXT_DIR/themes" ]; then
    echo -e "${GREEN}✓ Theme extension installed to $EXT_DIR${NC}"
else
    echo -e "${RED}❌ Failed to install theme extension${NC}"
    exit 1
fi

# Remove extensions.json so Cursor rebuilds it cleanly on next launch
EXT_JSON="$HOME/.cursor/extensions/extensions.json"
if [ -f "$EXT_JSON" ]; then
    rm -f "$EXT_JSON"
    echo -e "${GREEN}✓ Cleared extensions.json (Cursor will rebuild it)${NC}"
fi

echo ""
echo "🔧 Step 2: Installing Custom UI Style extension..."
if cursor --install-extension subframe7536.custom-ui-style --force; then
    echo -e "${GREEN}✓ Custom UI Style extension installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not install Custom UI Style extension automatically${NC}"
    echo "   Please install it manually from the Extensions marketplace"
fi

echo ""
echo "🔤 Step 3: Installing Bear Sans UI fonts..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    FONT_DIR="$HOME/Library/Fonts"
    echo "   Installing fonts to: $FONT_DIR"
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts installed to Font Book${NC}"
    echo "   Note: You may need to restart applications to use the new fonts"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    echo "   Installing fonts to: $FONT_DIR"
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not detect OS type for automatic font installation${NC}"
    echo "   Please manually install the fonts from the 'fonts/' folder"
fi

echo ""
echo "⚙️  Step 4: Applying Cursor settings..."
SETTINGS_DIR="$HOME/.config/Cursor/User"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Cursor/User"
fi

mkdir -p "$SETTINGS_DIR"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Backup existing settings if they exist
if [ -f "$SETTINGS_FILE" ]; then
    BACKUP_FILE="$SETTINGS_FILE.pre-islands-dark"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo -e "${YELLOW}⚠️  Existing settings.json backed up to:${NC}"
    echo "   $BACKUP_FILE"
    echo "   You can restore your old settings from this file if needed."
fi

# Copy Islands Dark settings (Cursor variant)
cp "$SCRIPT_DIR/settings-cursor.json" "$SETTINGS_FILE"
echo -e "${GREEN}✓ Islands Dark settings (Cursor variant) applied${NC}"

echo ""
echo "🚀 Step 5: Enabling Custom UI Style..."
echo "   Cursor will reload after applying changes..."

# Create a flag file to indicate first run
FIRST_RUN_FILE="$SCRIPT_DIR/.islands_dark_cursor_first_run"
if [ ! -f "$FIRST_RUN_FILE" ]; then
    touch "$FIRST_RUN_FILE"
    echo ""
    echo -e "${YELLOW}📝 Important Notes for Cursor users:${NC}"
    echo "   • IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    echo "   • After Cursor reloads, you may see a 'corrupt installation' warning"
    echo "   • This is expected — click the gear icon and select 'Don't Show Again'"
    echo "   • Custom UI Style is not officially supported on Cursor (works since v0.5.6+)"
    echo "   • The extension's webview patch is disabled to avoid CSP errors on the"
    echo "     extension detail panel (custom-ui-style.webview.enable is set to false)"
    echo "   • Cmd+B still toggles the sidebar even though the toggle button is hidden"
    echo "   • After every Cursor update, re-run 'Custom UI Style: Reload' to reapply"
    echo ""
    if [ -t 0 ]; then
        read -p "Press Enter to continue and reload Cursor..."
    fi
fi

echo "   Applying CSS customizations..."

echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "🎉 Islands Dark theme has been installed for Cursor!"
echo "   Cursor will now reload to apply the custom UI style."
echo ""

if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "Islands Dark theme installed for Cursor!" with title "🏝️ Islands Dark"' 2>/dev/null || true
fi

echo "   Reloading Cursor..."
cursor --reload-window 2>/dev/null || cursor . 2>/dev/null || true

echo ""
echo -e "${GREEN}Done! 🏝️${NC}"
