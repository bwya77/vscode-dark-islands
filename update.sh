#!/bin/bash

set -e

echo "🏝️  Islands Dark Theme Updater for macOS/Linux"
echo "=============================================="
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
    exit 1
fi

echo -e "${GREEN}✓ VS Code CLI found${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if this is a git repository
if [ -d "$SCRIPT_DIR/.git" ]; then
    echo ""
    echo "📥 Step 1: Pulling latest changes from repository..."

    cd "$SCRIPT_DIR"

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo -e "${YELLOW}⚠️  You have uncommitted changes in this directory${NC}"
        echo "   The update will continue, but your local changes may conflict"
        echo ""
        if [ -t 0 ]; then
            read -p "Continue? (y/n) " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Update cancelled"
                exit 0
            fi
        fi
    fi

    # Pull latest changes
    if git pull --quiet; then
        echo -e "${GREEN}✓ Repository updated to latest version${NC}"
    else
        echo -e "${RED}❌ Failed to pull latest changes${NC}"
        echo "   Please resolve any conflicts manually"
        exit 1
    fi
else
    echo ""
    echo "📦 Step 1: Checking for updates..."
    echo -e "${YELLOW}⚠️  This directory is not a git repository${NC}"
    echo "   Using local files for update"
fi

echo ""
echo "🔄 Step 2: Updating Islands Dark theme extension..."

# Update theme files by copying to VS Code extensions directory
EXT_DIR="$HOME/.vscode/extensions/bwya77.islands-dark-1.0.0"
rm -rf "$EXT_DIR"
mkdir -p "$EXT_DIR"
cp "$SCRIPT_DIR/package.json" "$EXT_DIR/"
cp -r "$SCRIPT_DIR/themes" "$EXT_DIR/"

if [ -d "$EXT_DIR/themes" ]; then
    echo -e "${GREEN}✓ Theme extension updated at $EXT_DIR${NC}"
else
    echo -e "${RED}❌ Failed to update theme extension${NC}"
    exit 1
fi

echo ""
echo "🔤 Step 3: Updating Bear Sans UI fonts..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    FONT_DIR="$HOME/Library/Fonts"
    echo "   Copying fonts to: $FONT_DIR"
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts updated${NC}"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    echo "   Copying fonts to: $FONT_DIR"
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts updated${NC}"
fi

echo ""
echo "⚙️  Step 4: Updating VS Code settings..."
SETTINGS_DIR="$HOME/.config/Code/User"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
fi

SETTINGS_FILE="$SETTINGS_DIR/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    echo "   Creating backup at settings.json.backup"
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

    # Merge settings using node.js if available
    if command -v node &> /dev/null; then
        node << 'NODE_SCRIPT'
const fs = require('fs');
const path = require('path');

// Strip JSONC features (comments and trailing commas) for JSON.parse
function stripJsonc(text) {
    // Remove single-line comments (but not // inside strings)
    text = text.replace(/\/\/(?=(?:[^"\\]|\\.)*$)/gm, '');
    // Remove multi-line comments
    text = text.replace(/\/\*[\s\S]*?\*\//g, '');
    // Remove trailing commas before } or ]
    text = text.replace(/,\s*([}\]])/g, '$1');
    return text;
}

const scriptDir = process.cwd();
const newSettings = JSON.parse(stripJsonc(fs.readFileSync(path.join(scriptDir, 'settings.json'), 'utf8')));

let settingsDir;
if (process.platform === 'darwin') {
    settingsDir = path.join(process.env.HOME, 'Library/Application Support/Code/User');
} else {
    settingsDir = path.join(process.env.HOME, '.config/Code/User');
}

const settingsFile = path.join(settingsDir, 'settings.json');
const existingText = fs.readFileSync(settingsFile, 'utf8');
const existingSettings = JSON.parse(stripJsonc(existingText));

// Merge settings - Islands Dark settings take precedence
const mergedSettings = { ...existingSettings, ...newSettings };

// Deep merge custom-ui-style.stylesheet
const stylesheetKey = 'custom-ui-style.stylesheet';
if (existingSettings[stylesheetKey] && newSettings[stylesheetKey]) {
    mergedSettings[stylesheetKey] = {
        ...existingSettings[stylesheetKey],
        ...newSettings[stylesheetKey]
    };
}

fs.writeFileSync(settingsFile, JSON.stringify(mergedSettings, null, 2));
console.log('Settings merged successfully');
NODE_SCRIPT
        echo -e "${GREEN}✓ Settings updated and merged${NC}"
    else
        echo -e "${YELLOW}   Node.js not found. Skipping settings merge.${NC}"
        echo "   If there are new settings, please manually merge settings.json from this repo"
    fi
else
    echo -e "${YELLOW}⚠️  Settings file not found. Skipping settings update.${NC}"
    echo "   Run install.sh if this is a fresh installation"
fi

echo ""
echo "🚀 Step 5: Reloading VS Code..."
echo "   Applying changes..."

# Reload VS Code to apply changes
if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "Islands Dark theme updated successfully!" with title "🏝️ Islands Dark"' 2>/dev/null || true
fi

code --reload-window 2>/dev/null || code . 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Update complete! 🏝️${NC}"
echo ""
echo "   Islands Dark theme has been updated to the latest version"
echo "   VS Code will reload to apply the changes"
echo ""
