#!/bin/bash

set -e


echo "🏝️  Islands Dark Theme Installer for macOS/Linux"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

EDITOR_TARGET="${ISLANDS_DARK_EDITOR:-auto}"
case "${1:-}" in
    --vscodium|--codium)
        EDITOR_TARGET="vscodium"
        ;;
    --vscode|--code)
        EDITOR_TARGET="vscode"
        ;;
    ""|--auto)
        ;;
    *)
        echo -e "${RED}❌ Unknown option: $1${NC}"
        echo "Usage: $0 [--vscode|--vscodium]"
        exit 1
        ;;
esac
case "$EDITOR_TARGET" in
    codium)
        EDITOR_TARGET="vscodium"
        ;;
    code)
        EDITOR_TARGET="vscode"
        ;;
esac

if [ "$EDITOR_TARGET" = "auto" ]; then
    if command -v code &> /dev/null; then
        EDITOR_TARGET="vscode"
    elif command -v codium &> /dev/null; then
        EDITOR_TARGET="vscodium"
    else
        EDITOR_TARGET="vscode"
    fi
fi

if [ "$EDITOR_TARGET" = "vscodium" ]; then
    EDITOR_NAME="VSCodium"
    EDITOR_CLI="codium"
    EXT_ROOT="$HOME/.vscode-oss/extensions"
    SETTINGS_DIR="$HOME/.config/VSCodium/User"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SETTINGS_DIR="$HOME/Library/Application Support/VSCodium/User"
    fi
else
    EDITOR_NAME="VS Code"
    EDITOR_CLI="code"
    EXT_ROOT="$HOME/.vscode/extensions"
    SETTINGS_DIR="$HOME/.config/Code/User"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
    fi
fi

# Check if editor command is available
if ! command -v "$EDITOR_CLI" &> /dev/null; then
    echo -e "${RED}❌ Error: $EDITOR_NAME CLI ($EDITOR_CLI) not found!${NC}"
    echo "Please install $EDITOR_NAME and make sure '$EDITOR_CLI' command is in your PATH."
    echo "You can do this by:"
    echo "  1. Open $EDITOR_NAME"
    echo "  2. Press Cmd+Shift+P (macOS) or Ctrl+Shift+P (Linux)"
    echo "  3. Type 'Shell Command: Install $EDITOR_CLI command in PATH'"
    exit 1
fi

echo -e "${GREEN}✓ $EDITOR_NAME CLI found${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "📦 Step 1: Installing Islands Dark theme extension..."

# Install by copying to editor extensions directory
EXT_DIR="$EXT_ROOT/bwya77.islands-dark-1.0.0"
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

EXT_JSON="$EXT_ROOT/extensions.json"
if [ -f "$EXT_JSON" ]; then
    rm -f "$EXT_JSON"
    echo -e "${GREEN}✓ Cleared extensions.json ($EDITOR_NAME will rebuild it)${NC}"
fi

echo ""
echo "🔧 Step 2: Installing Custom UI Style extension..."
if "$EDITOR_CLI" --install-extension subframe7536.custom-ui-style --force; then
    echo -e "${GREEN}✓ Custom UI Style extension installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not install Custom UI Style extension automatically${NC}"
    echo "   Please install it manually from the Extensions marketplace"
fi

echo ""
echo "🔤 Step 3: Installing Bear Sans UI fonts..."

# Track font pre-existence before installing
FONT_PRE_STATE=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    FONT_DIR="$HOME/Library/Fonts"
    echo "   Installing fonts to: $FONT_DIR"
    for f in "$SCRIPT_DIR/fonts/"*.otf; do
        [ -f "$f" ] || continue
        fname=$(basename "$f")
        if [ -f "$FONT_DIR/$fname" ]; then
            FONT_PRE_STATE="${FONT_PRE_STATE}\"${fname}\": {\"wasPresentBeforeInstall\": true, \"installedPath\": \"${FONT_DIR}/${fname}\"},"
        else
            FONT_PRE_STATE="${FONT_PRE_STATE}\"${fname}\": {\"wasPresentBeforeInstall\": false, \"installedPath\": \"${FONT_DIR}/${fname}\"},"
        fi
    done
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts installed to Font Book${NC}"
    echo "   Note: You may need to restart applications to use the new fonts"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    echo "   Installing fonts to: $FONT_DIR"
    for f in "$SCRIPT_DIR/fonts/"*.otf; do
        [ -f "$f" ] || continue
        fname=$(basename "$f")
        if [ -f "$FONT_DIR/$fname" ]; then
            FONT_PRE_STATE="${FONT_PRE_STATE}\"${fname}\": {\"wasPresentBeforeInstall\": true, \"installedPath\": \"${FONT_DIR}/${fname}\"},"
        else
            FONT_PRE_STATE="${FONT_PRE_STATE}\"${fname}\": {\"wasPresentBeforeInstall\": false, \"installedPath\": \"${FONT_DIR}/${fname}\"},"
        fi
    done
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not detect OS type for automatic font installation${NC}"
    echo "   Please manually install the fonts from the 'fonts/' folder"
fi
# Remove trailing comma from font state
FONT_PRE_STATE="${FONT_PRE_STATE%,}"

echo ""
echo "⚙️  Step 4: Applying $EDITOR_NAME settings..."

mkdir -p "$SETTINGS_DIR"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Backup existing settings if they exist, then merge
if [ -f "$SETTINGS_FILE" ]; then
    TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
    BACKUP_FILE="$SETTINGS_FILE.pre-islands-dark.$TIMESTAMP"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo -e "${YELLOW}⚠️  Existing settings.json backed up to:${NC}"
    echo "   $BACKUP_FILE"
    echo "   You can restore your old settings from this file if needed."

    if command -v jq &> /dev/null; then
        # Merge: user's non-theme settings are preserved, Islands Dark theme keys win
        # This ensures updated fixes are applied while keeping user customizations
        if MERGED=$(jq -s '.[0] * .[1]' "$SETTINGS_FILE" "$SCRIPT_DIR/settings.json" 2>/dev/null); then
            echo "$MERGED" > "$SETTINGS_FILE"
            echo -e "${GREEN}✓ Settings merged (your non-theme settings preserved, theme settings updated)${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not parse existing settings.json - leaving it untouched${NC}"
            echo "   Your backup is at: $BACKUP_FILE"
            echo "   To apply Islands Dark settings, manually merge from: $SCRIPT_DIR/settings.json"
        fi
    else
        echo -e "${YELLOW}⚠️  jq not found - cannot merge settings safely${NC}"
        echo "   Your backup is at: $BACKUP_FILE"
        echo "   To apply Islands Dark settings, manually merge from: $SCRIPT_DIR/settings.json"
        echo "   Or install jq (https://jqlang.github.io/jq/) and re-run this script"
    fi
else
    # No existing settings - just copy
    cp "$SCRIPT_DIR/settings.json" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Islands Dark settings applied${NC}"
fi

# Save pre-install state for clean uninstall (only on first install)
STATE_FILE="$SETTINGS_DIR/.islands-dark-state.json"
if [ ! -f "$STATE_FILE" ]; then
    PREV_THEME="Default Dark+"
    PREV_ICON_THEME=""
    CUI_WAS_INSTALLED="false"
    BACKUP_PATH="${BACKUP_FILE:-}"

    # Read previous theme from backup
    if [ -n "$BACKUP_PATH" ] && [ -f "$BACKUP_PATH" ]; then
        if command -v jq &> /dev/null; then
            PREV_THEME=$(jq -r '."workbench.colorTheme" // "Default Dark+"' "$BACKUP_PATH" 2>/dev/null || echo "Default Dark+")
            PREV_ICON_THEME=$(jq -r '."workbench.iconTheme" // ""' "$BACKUP_PATH" 2>/dev/null || echo "")
        fi
    fi

    # Check if Custom UI Style was already installed
    if ls "$EXT_ROOT"/subframe7536.custom-ui-style-* 1>/dev/null 2>&1; then
        CUI_WAS_INSTALLED="true"
    fi

    cat > "$STATE_FILE" << STATEEOF
{
  "previousColorTheme": "$PREV_THEME",
  "previousIconTheme": "$PREV_ICON_THEME",
  "customUiStyleWasInstalled": $CUI_WAS_INSTALLED,
  "settingsBackupPath": "$BACKUP_PATH",
  "fonts": {${FONT_PRE_STATE}},
  "installedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
STATEEOF
    echo -e "${GREEN}✓ Pre-install state saved for clean uninstall${NC}"
fi

echo ""
echo "🚀 Step 5: Enabling Custom UI Style..."
echo "   $EDITOR_NAME will reload after applying changes..."

# Create a flag file to indicate first run
FIRST_RUN_FILE="$SCRIPT_DIR/.islands_dark_first_run"
if [ ! -f "$FIRST_RUN_FILE" ]; then
    touch "$FIRST_RUN_FILE"
    echo ""
    echo -e "${YELLOW}📝 Important Notes:${NC}"
    echo "   • IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    echo "   • After $EDITOR_NAME reloads, you may see a 'corrupt installation' warning"
    echo "   • This is expected - click the gear icon and select 'Don't Show Again'"
    echo ""
    if [ -t 0 ]; then
        read -p "Press Enter to continue and reload $EDITOR_NAME..."
    fi
fi

# Apply custom UI style
echo "   Applying CSS customizations..."

# Reload editor to apply changes
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "🎉 Islands Dark theme has been installed!"
echo "   $EDITOR_NAME will now reload to apply the custom UI style."
echo ""

# Use AppleScript on macOS to show a notification and reload editor
if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "Islands Dark theme installed successfully!" with title "🏝️ Islands Dark"' 2>/dev/null || true
fi

echo "   Reloading $EDITOR_NAME..."
"$EDITOR_CLI" --reload-window 2>/dev/null || "$EDITOR_CLI" . 2>/dev/null || true

echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN} IMPORTANT: One more step required!${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
echo -e "${YELLOW}To activate the custom UI styling:${NC}"
echo "   1. Wait for $EDITOR_NAME to finish loading"
echo "   2. Press Cmd+Shift+P (macOS) or Ctrl+Shift+P (Linux)"
echo -e "   3. Type: ${GREEN}Custom UI Style: Reload${NC}"
echo "   4. Press Enter and $EDITOR_NAME will reload with the new styling"
echo ""
echo "   You only need to do this once (or after $EDITOR_NAME updates)."
echo ""
