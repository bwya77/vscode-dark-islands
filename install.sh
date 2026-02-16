#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Parse arguments ---
TARGET_IDE=""
show_help() {
    echo "Usage: $0 [--ide <windsurf|code>] [--no-prompt]"
    echo ""
    echo "Options:"
    echo "  --ide <windsurf|code>  Target IDE (default: auto-detect)"
    echo "  --no-prompt            Skip interactive prompts"
    echo "  -h, --help             Show this help message"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ide)
            TARGET_IDE="$2"
            shift 2
            ;;
        --no-prompt)
            ISLANDS_DARK_NO_PROMPT=1
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            ;;
    esac
done

# Validate --ide value if provided
if [ -n "$TARGET_IDE" ] && [ "$TARGET_IDE" != "windsurf" ] && [ "$TARGET_IDE" != "code" ]; then
    echo -e "${RED}❌ Invalid --ide value: $TARGET_IDE${NC}"
    echo "   Supported values: windsurf, code"
    exit 1
fi

# Auto-detect if --ide not specified
if [ -z "$TARGET_IDE" ]; then
    if command -v windsurf &> /dev/null; then
        TARGET_IDE="windsurf"
    elif command -v code &> /dev/null; then
        TARGET_IDE="code"
    else
        echo -e "${RED}❌ No supported editor CLI found (windsurf / code)${NC}"
        echo "   Please specify the target IDE manually: $0 --ide <windsurf|code>"
        exit 1
    fi
    echo -e "${GREEN}✓ Auto-detected IDE: $TARGET_IDE${NC}"
fi

# --- Set IDE-specific paths ---
if [ "$TARGET_IDE" = "windsurf" ]; then
    IDE_NAME="Windsurf"
    EDITOR_CLI="windsurf"
    EXT_BASE_DIR="$HOME/.windsurf/extensions"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SETTINGS_DIR="$HOME/Library/Application Support/Windsurf/User"
    else
        SETTINGS_DIR="$HOME/.config/Windsurf/User"
    fi
else
    IDE_NAME="VS Code"
    EDITOR_CLI="code"
    EXT_BASE_DIR="$HOME/.vscode/extensions"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
    else
        SETTINGS_DIR="$HOME/.config/Code/User"
    fi
fi

# Allow env override for settings directory
if [ -n "${ISLANDS_DARK_SETTINGS_DIR:-}" ]; then
    SETTINGS_DIR="$ISLANDS_DARK_SETTINGS_DIR"
fi

# Check if the chosen CLI is actually available
HAS_CLI=true
if ! command -v "$EDITOR_CLI" &> /dev/null; then
    HAS_CLI=false
fi

echo "🏝️  Islands Dark Theme Installer for macOS/Linux"
echo "================================================"
echo -e "   Target IDE: ${GREEN}${IDE_NAME}${NC}"
echo ""

if [ "$HAS_CLI" = true ]; then
    echo -e "${GREEN}✓ $IDE_NAME CLI found: $EDITOR_CLI${NC}"
else
    echo -e "${YELLOW}⚠️  $IDE_NAME CLI ($EDITOR_CLI) not found in PATH${NC}"
    echo "   Will skip automatic marketplace installs and window reload."
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "📦 Step 1: Installing Islands Dark theme extension..."

# Install by copying to extensions directory
EXT_DIR="$EXT_BASE_DIR/bwya77.islands-dark-1.0.0"
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

echo ""
echo "🔧 Step 2: Installing Custom UI Style extension..."
if [ "$HAS_CLI" = true ]; then
    if "$EDITOR_CLI" --install-extension subframe7536.custom-ui-style --force; then
        echo -e "${GREEN}✓ Custom UI Style extension installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not install Custom UI Style extension automatically${NC}"
        echo "   Please install it manually from the $IDE_NAME Extensions marketplace"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping automatic install: $IDE_NAME CLI not available${NC}"
    echo "   Please install manually: subframe7536.custom-ui-style"
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
echo "⚙️  Step 4: Applying $IDE_NAME settings..."

mkdir -p "$SETTINGS_DIR"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Check if settings.json exists
if [ -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}⚠️  Existing settings.json found${NC}"
    echo "   Backing up to settings.json.backup"
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

    # Read the existing settings and merge
    echo "   Merging Islands Dark settings with your existing settings..."

    # Create a temporary file with the merge logic using node.js if available
    if command -v node &> /dev/null; then
        SCRIPT_DIR="$SCRIPT_DIR" SETTINGS_FILE="$SETTINGS_FILE" node << 'NODE_SCRIPT'
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

const scriptDir = process.env.SCRIPT_DIR || process.cwd();
const settingsFile = process.env.SETTINGS_FILE;
if (!settingsFile) {
    throw new Error('SETTINGS_FILE env not set');
}

const newSettings = JSON.parse(stripJsonc(fs.readFileSync(path.join(scriptDir, 'settings.json'), 'utf8')));
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
    else
        echo -e "${YELLOW}   Node.js not found. Please manually merge settings.json from this repo into your $IDE_NAME settings.${NC}"
        echo "   Your original settings have been backed up to settings.json.backup"
    fi
else
    # No existing settings, just copy
    cp "$SCRIPT_DIR/settings.json" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Settings applied${NC}"
fi

echo ""
echo "🚀 Step 5: Enabling Custom UI Style..."
echo "   Your editor will reload after applying changes..."

# Create a flag file to indicate first run
FIRST_RUN_FILE="$SCRIPT_DIR/.islands_dark_first_run"
if [ ! -f "$FIRST_RUN_FILE" ]; then
    touch "$FIRST_RUN_FILE"
    echo ""
    echo -e "${YELLOW}📝 Important Notes:${NC}"
    echo "   • IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    echo "   • After $IDE_NAME reloads, you may see a 'corrupt installation' warning"
    echo "   • This is expected - click the gear icon and select 'Don't Show Again'"
    echo ""
    if [ -t 0 ] && [ "${ISLANDS_DARK_NO_PROMPT:-0}" != "1" ]; then
        read -p "Press Enter to continue and reload..."
    fi
fi

# Apply custom UI style
echo "   Applying CSS customizations..."

# Reload editor to apply changes
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "🎉 Islands Dark theme has been installed!"
echo "   Your editor will now reload to apply the custom UI style."
echo ""

# Use AppleScript on macOS to show a notification
if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "Islands Dark theme installed successfully!" with title "🏝️ Islands Dark"' 2>/dev/null || true
fi

if [ "$HAS_CLI" = true ]; then
    echo "   Reloading $IDE_NAME..."
    "$EDITOR_CLI" --reload-window 2>/dev/null || "$EDITOR_CLI" "$SCRIPT_DIR" 2>/dev/null || true
else
    echo -e "${YELLOW}⚠️  Skipping reload: $IDE_NAME CLI not available${NC}"
    echo "   Please restart $IDE_NAME manually to apply changes."
fi

echo ""
echo -e "${GREEN}Done! 🏝️${NC}"
