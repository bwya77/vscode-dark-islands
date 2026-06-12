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
    if [[ "$OSTYPE" == "darwin"* ]]; then
        EDITOR_DIRS=("/Applications/VSCodium.app/Contents/Resources/app/out")
    else
        EDITOR_DIRS=(
            "/usr/share/codium/resources/app/out"
            "/usr/lib/codium/resources/app/out"
            "/opt/visual-studio-codium/resources/app/out"
            "/snap/codium/current/usr/share/codium/resources/app/out"
        )
    fi
else
    EDITOR_NAME="VS Code"
    EDITOR_CLI="code"
    EXT_ROOT="$HOME/.vscode/extensions"
    SETTINGS_DIR="$HOME/.config/Code/User"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
    fi
    if [[ "$OSTYPE" == "darwin"* ]]; then
        EDITOR_DIRS=("/Applications/Visual Studio Code.app/Contents/Resources/app/out")
    else
        EDITOR_DIRS=(
            "/usr/share/code/resources/app/out"
            "/usr/lib/code/resources/app/out"
            "/opt/visual-studio-code/resources/app/out"
            "/snap/code/current/usr/share/code/resources/app/out"
        )
    fi
fi

# Check if editor command is available
HAS_CLI=false
if command -v "$EDITOR_CLI" &> /dev/null; then
    HAS_CLI=true
    echo -e "${GREEN}✓ $EDITOR_NAME CLI found${NC}"
else
    echo -e "${YELLOW}⚠️  $EDITOR_NAME CLI not found - will skip CLI operations${NC}"
fi
echo ""

SETTINGS_FILE="$SETTINGS_DIR/settings.json"
STATE_FILE="$SETTINGS_DIR/.islands-dark-state.json"

# Load pre-install state if available
PREV_THEME="Default Dark+"
PREV_ICON_THEME=""
CUI_WAS_INSTALLED="false"
BACKUP_PATH=""
HAS_STATE=false

if [ -f "$STATE_FILE" ]; then
    HAS_STATE=true
    echo -e "${GREEN}✓ Found pre-install state file${NC}"
    if command -v jq &> /dev/null; then
        PREV_THEME=$(jq -r '.previousColorTheme // "Default Dark+"' "$STATE_FILE" 2>/dev/null || echo "Default Dark+")
        PREV_ICON_THEME=$(jq -r '.previousIconTheme // ""' "$STATE_FILE" 2>/dev/null || echo "")
        CUI_WAS_INSTALLED=$(jq -r '.customUiStyleWasInstalled // false' "$STATE_FILE" 2>/dev/null || echo "false")
        BACKUP_PATH=$(jq -r '.settingsBackupPath // ""' "$STATE_FILE" 2>/dev/null || echo "")
    fi
fi

# Step 1: Restore editor settings
echo "⚙️  Step 1: Restoring $EDITOR_NAME settings..."

RESTORED=false

# Try to restore from the exact backup recorded in state file
if [ -n "$BACKUP_PATH" ] && [ -f "$BACKUP_PATH" ]; then
    cp "$BACKUP_PATH" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Settings restored from original backup${NC}"
    echo "   Source: $BACKUP_PATH"
    RESTORED=true
fi

# Fall back to latest timestamped backup
if [ "$RESTORED" = false ] && [ -d "$SETTINGS_DIR" ]; then
    LATEST_BACKUP=$(ls -t "$SETTINGS_DIR"/settings.json.pre-islands-dark* 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ] && [ -f "$LATEST_BACKUP" ]; then
        cp "$LATEST_BACKUP" "$SETTINGS_FILE"
        echo -e "${GREEN}✓ Settings restored from backup${NC}"
        echo "   Source: $LATEST_BACKUP"
        RESTORED=true
    fi
fi

# If no backup exists, surgically remove Islands Dark keys
if [ "$RESTORED" = false ] && [ -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}⚠️  No backup found - surgically removing Islands Dark settings...${NC}"
    if command -v jq &> /dev/null; then
        CLEANED=$(jq --arg theme "$PREV_THEME" --arg icon "$PREV_ICON_THEME" '
            del(."// Islands Dark Settings v0.0.3") |
            del(."// Islands Dark Settings v0.0.2") |
            del(."custom-ui-style.stylesheet") |
            del(."custom-ui-style.font") |
            del(."chat.viewSessions.orientation") |
            . + {"workbench.colorTheme": $theme} |
            if $icon != "" then . + {"workbench.iconTheme": $icon} else del(."workbench.iconTheme") end
        ' "$SETTINGS_FILE" 2>/dev/null)
        if [ -n "$CLEANED" ]; then
            echo "$CLEANED" > "$SETTINGS_FILE"
            echo -e "${GREEN}✓ Islands Dark settings removed, previous theme restored${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not modify settings - please update manually${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  jq not found - please manually remove Islands Dark settings${NC}"
    fi
elif [ "$RESTORED" = false ]; then
    echo -e "${YELLOW}⚠️  No settings.json found${NC}"
fi

# Step 2: Remove Islands Dark theme extension
echo ""
echo "🗑️  Step 2: Removing Islands Dark theme extension..."
EXT_DIR="$EXT_ROOT/bwya77.islands-dark-1.0.0"
if [ -d "$EXT_DIR" ] || [ -L "$EXT_DIR" ]; then
    rm -rf "$EXT_DIR"
    echo -e "${GREEN}✓ Theme extension directory removed${NC}"
else
    echo -e "${YELLOW}⚠️  Extension directory not found (may already be removed)${NC}"
fi

if [ "$HAS_CLI" = true ]; then
    "$EDITOR_CLI" --uninstall-extension bwya77.islands-dark --force 2>/dev/null && \
        echo -e "${GREEN}✓ Extension uninstalled via $EDITOR_NAME CLI${NC}" || true
fi

# Step 3: Handle Custom UI Style extension
echo ""
echo "🔧 Step 3: Handling Custom UI Style extension..."

if [ "$CUI_WAS_INSTALLED" = "true" ]; then
    echo -e "${GREEN}✓ Custom UI Style was installed before Islands Dark - leaving it installed${NC}"
    echo "   The Islands Dark CSS rules have been removed from your settings."
else
    if [ "$HAS_CLI" = true ]; then
        "$EDITOR_CLI" --uninstall-extension subframe7536.custom-ui-style --force 2>/dev/null && \
            echo -e "${GREEN}✓ Custom UI Style extension uninstalled${NC}" || \
            echo -e "${YELLOW}⚠️  Custom UI Style may already be removed${NC}"
    else
        echo -e "${YELLOW}⚠️  Please uninstall Custom UI Style manually from $EDITOR_NAME Extensions${NC}"
    fi
fi

# Step 3b: Restore editor workbench files patched by Custom UI Style
echo ""
echo "🔧 Step 3b: Removing Custom UI Style CSS patches..."

CUI_RESTORED=0
for vscode_base in "${EDITOR_DIRS[@]}"; do
    [ -d "$vscode_base" ] || continue

    # Custom UI Style saves originals as *.custom-ui-style.{ext}
    while IFS= read -r backup; do
        [ -f "$backup" ] || continue
        # Derive original: workbench.custom-ui-style.html -> workbench.html
        original=$(echo "$backup" | sed 's/\.custom-ui-style\././')
        if [ -f "$original" ]; then
            cp "$backup" "$original" 2>/dev/null && rm -f "$backup" 2>/dev/null && CUI_RESTORED=$((CUI_RESTORED + 1)) || true
        fi
    done < <(find "$vscode_base" -name "*.custom-ui-style.*" -type f 2>/dev/null)
    break
done

if [ "$CUI_RESTORED" -gt 0 ]; then
    echo -e "${GREEN}✓ $CUI_RESTORED $EDITOR_NAME file(s) restored to original state${NC}"
else
    echo "   No Custom UI Style patches found (already clean)"
fi

# Step 4: Remove fonts that we installed
echo ""
echo "🔤 Step 4: Removing installed fonts..."

if [ "$HAS_STATE" = true ] && command -v jq &> /dev/null; then
    REMOVED_COUNT=0
    for fname in $(jq -r '.fonts | keys[]' "$STATE_FILE" 2>/dev/null); do
        WAS_PRESENT=$(jq -r ".fonts.\"$fname\".wasPresentBeforeInstall" "$STATE_FILE" 2>/dev/null)
        FONT_PATH=$(jq -r ".fonts.\"$fname\".installedPath" "$STATE_FILE" 2>/dev/null)
        if [ "$WAS_PRESENT" = "false" ] && [ -n "$FONT_PATH" ] && [ -f "$FONT_PATH" ]; then
            rm -f "$FONT_PATH"
            REMOVED_COUNT=$((REMOVED_COUNT + 1))
        fi
    done
    if [ "$REMOVED_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ $REMOVED_COUNT font(s) removed${NC}"
        fc-cache -f 2>/dev/null || true
    else
        echo "   No fonts to remove (all were pre-existing)"
    fi
else
    echo -e "${YELLOW}⚠️  No font state found - skipping font removal${NC}"
    echo "   You can manually remove Bear Sans UI fonts if needed"
fi

# Step 5: Clean up state and backup files
echo ""
echo "🧹 Step 5: Cleaning up..."

if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
    echo "   State file removed"
fi

# Clean up backup files
BACKUP_COUNT=$(ls "$SETTINGS_DIR"/settings.json.pre-islands-dark* 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 0 ]; then
    rm -f "$SETTINGS_DIR"/settings.json.pre-islands-dark*
    echo "   $BACKUP_COUNT backup file(s) removed"
fi

# Step 6: Reload editor
echo ""
echo "🔄 Step 6: Reloading $EDITOR_NAME..."

if [ "$HAS_CLI" = true ]; then
    "$EDITOR_CLI" --reload-window 2>/dev/null || "$EDITOR_CLI" . 2>/dev/null || true
    echo -e "${GREEN}✓ $EDITOR_NAME reload triggered${NC}"
else
    echo -e "${YELLOW}⚠️  Please restart $EDITOR_NAME manually to complete the uninstall${NC}"
fi

echo ""
echo -e "${GREEN}✓ Islands Dark has been uninstalled!${NC}"
echo ""
echo -e "${YELLOW}Note: If you see CSS artifacts, open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)${NC}"
echo -e "${YELLOW}and run 'Custom UI Style: Disable' to clean up injected styles.${NC}"
echo ""
