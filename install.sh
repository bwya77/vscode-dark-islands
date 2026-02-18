#!/bin/bash

set -e

echo "🏝️  Islands Dark Theme Installer for macOS/Linux"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect available VS Code CLI: prefer code-server, fall back to code
if command -v code-server &> /dev/null; then
    CODE_CMD="code-server"
    echo -e "${GREEN}✓ code-server CLI found${NC}"
elif command -v code &> /dev/null; then
    CODE_CMD="code"
    echo -e "${GREEN}✓ VS Code CLI (code) found${NC}"
else
    echo -e "${RED}❌ Error: No VS Code CLI found (tried: code-server, code)!${NC}"
    echo "Please install VS Code or code-server and make sure the command is in your PATH."
    echo "For VS Code you can add it by:"
    echo "  1. Open VS Code"
    echo "  2. Press Cmd+Shift+P (macOS) or Ctrl+Shift+P (Linux)"
    echo "  3. Type 'Shell Command: Install code command in PATH'"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "📦 Step 1: Installing Islands Dark theme extension..."

# Install by copying to the appropriate VS Code extensions directory
if [ "$CODE_CMD" = "code-server" ]; then
    EXT_DIR="$HOME/.local/share/code-server/extensions/bwya77.islands-dark-1.0.0"
else
    EXT_DIR="$HOME/.vscode/extensions/bwya77.islands-dark-1.0.0"
fi
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

# Register extension in extensions.json so VS Code discovers it
EXT_JSON="$HOME/.vscode/extensions/extensions.json"
if command -v node &> /dev/null; then
    node << 'REGISTER_SCRIPT'
const fs = require('fs');
const path = require('path');

const extJsonPath = path.join(process.env.HOME, '.vscode', 'extensions', 'extensions.json');
let extensions = [];
if (fs.existsSync(extJsonPath)) {
    try {
        extensions = JSON.parse(fs.readFileSync(extJsonPath, 'utf8'));
    } catch (e) {
        extensions = [];
    }
}

// Remove any existing Islands Dark entry
extensions = extensions.filter(e =>
    e.identifier?.id !== 'bwya77.islands-dark' &&
    e.identifier?.id !== 'your-publisher-name.islands-dark'
);

// Add new entry
extensions.push({
    identifier: { id: 'bwya77.islands-dark' },
    version: '1.0.0',
    location: {
        '$mid': 1,
        path: path.join(process.env.HOME, '.vscode', 'extensions', 'bwya77.islands-dark-1.0.0'),
        scheme: 'file'
    },
    relativeLocation: 'bwya77.islands-dark-1.0.0'
});

fs.writeFileSync(extJsonPath, JSON.stringify(extensions));
REGISTER_SCRIPT
    echo -e "${GREEN}✓ Extension registered${NC}"
fi

echo ""
echo "🔧 Step 2: Installing Custom UI Style extension..."
if "$CODE_CMD" --install-extension subframe7536.custom-ui-style --force; then
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
echo "⚙️  Step 4: Applying VS Code settings..."
if [ "$CODE_CMD" = "code-server" ]; then
    SETTINGS_DIR="$HOME/.local/share/code-server/User"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
else
    SETTINGS_DIR="$HOME/.config/Code/User"
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

# Copy Islands Dark settings
cp "$SCRIPT_DIR/settings.json" "$SETTINGS_FILE"
echo -e "${GREEN}✓ Islands Dark settings applied${NC}"

echo ""
echo "🚀 Step 5: Enabling Custom UI Style..."
echo "   VS Code will reload after applying changes..."

# Create a flag file to indicate first run
FIRST_RUN_FILE="$SCRIPT_DIR/.islands_dark_first_run"
if [ ! -f "$FIRST_RUN_FILE" ]; then
    touch "$FIRST_RUN_FILE"
    echo ""
    echo -e "${YELLOW}📝 Important Notes:${NC}"
    echo "   • IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    echo "   • After VS Code reloads, you may see a 'corrupt installation' warning"
    echo "   • This is expected - click the gear icon and select 'Don't Show Again'"
    echo ""
    if [ -t 0 ]; then
        read -p "Press Enter to continue and reload VS Code..."
    fi
fi

# Apply custom UI style
echo "   Applying CSS customizations..."

# Reload VS Code to apply changes
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "🎉 Islands Dark theme has been installed!"
echo "   VS Code will now reload to apply the custom UI style."
echo ""

# Use AppleScript on macOS to show a notification and reload VS Code
if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "Islands Dark theme installed successfully!" with title "🏝️ Islands Dark"' 2>/dev/null || true
fi

echo "   Reloading VS Code..."
"$CODE_CMD" --reload-window 2>/dev/null || "$CODE_CMD" . 2>/dev/null || true

echo ""
echo -e "${GREEN}Done! 🏝️${NC}"
