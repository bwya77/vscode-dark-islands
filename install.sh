#!/bin/bash
#
# Islands Dark Theme Installer for macOS/Linux
# Usage:
#   ./install.sh              - Install or update the theme
#   ./install.sh --check      - Only check for updates without installing
#   ./install.sh --force      - Force reinstall even if on latest version

set -e

# Parse command line arguments
CHECK_UPDATE=false
FORCE_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --check|-c)
            CHECK_UPDATE=true
            shift
            ;;
        --force|-f)
            FORCE_INSTALL=true
            shift
            ;;
        --help|-h)
            echo "Islands Dark Theme Installer"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --check, -c     Only check for updates, don't install"
            echo "  --force, -f     Force reinstall even if already on latest version"
            echo "  --help, -h      Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Version information
SCRIPT_VERSION="1.0.0"
EXTENSION_ID="bwya77.islands-dark"

echo "🏝️  Islands Dark Theme Installer for macOS/Linux"
echo "================================================"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Read the version from package.json in the repo
REPO_VERSION="$SCRIPT_VERSION"
if [ -f "$SCRIPT_DIR/package.json" ]; then
    if command -v jq &> /dev/null; then
        REPO_VERSION=$(jq -r '.version' "$SCRIPT_DIR/package.json")
    else
        # Fallback: extract version using grep/sed
        REPO_VERSION=$(grep '"version"' "$SCRIPT_DIR/package.json" | head -1 | sed 's/.*: "\([^"]*\)".*/\1/')
    fi
fi

# Function to get installed version
get_installed_version() {
    local ext_dir="$HOME/.vscode/extensions/${EXTENSION_ID}-${REPO_VERSION}"
    local generic_ext_dir="$HOME/.vscode/extensions/${EXTENSION_ID}-"
    
    # Check for exact version match first
    if [ -d "$ext_dir" ] && [ -f "$ext_dir/package.json" ]; then
        if command -v jq &> /dev/null; then
            jq -r '.version' "$ext_dir/package.json" 2>/dev/null
            return
        else
            grep '"version"' "$ext_dir/package.json" | head -1 | sed 's/.*: "\([^"]*\)".*/\1/'
            return
        fi
    fi
    
    # Check for any version of the extension
    local found_dir=$(find "$HOME/.vscode/extensions" -maxdepth 1 -name "${EXTENSION_ID}-*" -type d 2>/dev/null | head -1)
    if [ -n "$found_dir" ] && [ -f "$found_dir/package.json" ]; then
        if command -v jq &> /dev/null; then
            jq -r '.version' "$found_dir/package.json" 2>/dev/null
            return
        else
            grep '"version"' "$found_dir/package.json" | head -1 | sed 's/.*: "\([^"]*\)".*/\1/'
            return
        fi
    fi
    
    echo ""
}

# Check current version
INSTALLED_VERSION=$(get_installed_version)

# Display version information
echo -e "${CYAN}Repository version: $REPO_VERSION${NC}"
if [ -n "$INSTALLED_VERSION" ]; then
    echo -e "${CYAN}Installed version:  $INSTALLED_VERSION${NC}"
else
    echo -e "${YELLOW}Installed version:  Not installed${NC}"
fi
echo ""

# Check update mode - just display status and exit
if [ "$CHECK_UPDATE" = true ]; then
    if [ -z "$INSTALLED_VERSION" ]; then
        echo -e "${YELLOW}Islands Dark is not installed.${NC}"
        echo "Run without --check to install."
        exit 0
    fi
    
    if [ "$INSTALLED_VERSION" = "$REPO_VERSION" ]; then
        echo -e "${GREEN}You have the latest version ($REPO_VERSION) installed!${NC}"
        exit 0
    else
        echo -e "${YELLOW}Update available: $INSTALLED_VERSION -> $REPO_VERSION${NC}"
        echo "Run without --check to update."
        exit 0
    fi
fi

# Check if we should proceed with installation
if [ "$INSTALLED_VERSION" = "$REPO_VERSION" ] && [ "$FORCE_INSTALL" = false ]; then
    echo -e "${GREEN}Islands Dark version $REPO_VERSION is already installed.${NC}"
    echo ""
    echo -e "${CYAN}Options:${NC}"
    echo "  • Run with --force to reinstall anyway"
    echo "  • Run with --check to just check for updates"
    echo ""
    
    if [ -t 0 ]; then
        read -p "Do you want to reinstall anyway? (y/N) " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installation cancelled.${NC}"
            exit 0
        fi
    else
        echo "Non-interactive mode detected. Use --force to reinstall."
        exit 0
    fi
    echo ""
fi

# Check if code command is available
if ! command -v code &> /dev/null; then
    echo -e "${RED}❌ Error: VS Code: CLI (code) not found!${NC}"
    echo "Please install VS Code: and make sure 'code' command is in your PATH."
    echo "You can do this by:"
    echo "  1. Open VS Code:"
    echo "  2. Press Cmd+Shift+P (macOS) or Ctrl+Shift+P (Linux)"
    echo "  3. Type 'Shell Command: Install code command in PATH'"
    exit 1
fi

echo -e "${GREEN}✓ VS Code: CLI found${NC}"

echo ""
echo "📦 Step 1: Installing Islands Dark theme extension..."

# Install by copying to VS Code: extensions directory
EXT_DIR="$HOME/.vscode/extensions/${EXTENSION_ID}-${REPO_VERSION}"

# Remove old versions of the extension
for old_dir in "$HOME/.vscode/extensions/${EXTENSION_ID}"-*; do
    if [ -d "$old_dir" ] && [ "$(basename "$old_dir")" != "${EXTENSION_ID}-${REPO_VERSION}" ]; then
        echo "  Removing old version: $(basename "$old_dir")"
        rm -rf "$old_dir"
    fi
done

# Install new version
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
if code --install-extension subframe7536.custom-ui-style --force; then
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
echo "⚙️  Step 4: Applying VS Code: settings..."
SETTINGS_DIR="$HOME/.config/Code:/User"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Code:/User"
fi

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
    settingsDir = path.join(process.env.HOME, 'Library/Application Support/Code:/User');
} else {
    settingsDir = path.join(process.env.HOME, '.config/Code:/User');
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
    else
        echo -e "${YELLOW}   Node.js not found. Please manually merge settings.json from this repo into your VS Code: settings.${NC}"
        echo "   Your original settings have been backed up to settings.json.backup"
    fi
else
    # No existing settings, just copy
    cp "$SCRIPT_DIR/settings.json" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Settings applied${NC}"
fi

echo ""
echo "🚀 Step 5: Enabling Custom UI Style..."
echo "   VS Code: will reload after applying changes..."

# Create a flag file to indicate first run
FIRST_RUN_FILE="$SCRIPT_DIR/.islands_dark_first_run"
if [ ! -f "$FIRST_RUN_FILE" ]; then
    touch "$FIRST_RUN_FILE"
    echo ""
    echo -e "${YELLOW}📝 Important Notes:${NC}"
    echo "   • IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    echo "   • After VS Code: reloads, you may see a 'corrupt installation' warning"
    echo "   • This is expected - click the gear icon and select 'Don't Show Again'"
    echo ""
    if [ -t 0 ]; then
        read -p "Press Enter to continue and reload VS Code:..."
    fi
fi

# Apply custom UI style
echo "   Applying CSS customizations..."

# Reload VS Code: to apply changes
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "🎉 Islands Dark theme has been installed!"
echo "   VS Code: will now reload to apply the custom UI style."
echo ""

# Use AppleScript on macOS to show a notification and reload VS Code:
if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "Islands Dark theme installed successfully!" with title "🏝️ Islands Dark"' 2>/dev/null || true
fi

echo "   Reloading VS Code:..."
code --reload-window 2>/dev/null || code . 2>/dev/null || true

echo ""
echo -e "${GREEN}Done! 🏝️${NC}"
