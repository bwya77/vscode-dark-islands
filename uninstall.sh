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
HAS_CLI=false
if command -v code &> /dev/null; then
    HAS_CLI=true
    echo -e "${GREEN}✓ VS Code CLI found${NC}"
else
    echo -e "${YELLOW}⚠️  VS Code CLI not found - will skip CLI operations${NC}"
fi
echo ""

# Determine settings directory
SETTINGS_DIR="$HOME/.config/Code/User"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
fi

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

# Step 1: Restore VS Code settings
echo "⚙️  Step 1: Restoring VS Code settings..."

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
EXT_DIR="$HOME/.vscode/extensions/bwya77.islands-dark-1.0.0"
if [ -d "$EXT_DIR" ] || [ -L "$EXT_DIR" ]; then
    rm -rf "$EXT_DIR"
    echo -e "${GREEN}✓ Theme extension directory removed${NC}"
else
    echo -e "${YELLOW}⚠️  Extension directory not found (may already be removed)${NC}"
fi

if [ "$HAS_CLI" = true ]; then
    code --uninstall-extension bwya77.islands-dark --force 2>/dev/null && \
        echo -e "${GREEN}✓ Extension uninstalled via VS Code CLI${NC}" || true
fi

# Step 3: Handle Custom UI Style extension
echo ""
echo "🔧 Step 3: Handling Custom UI Style extension..."

if [ "$CUI_WAS_INSTALLED" = "true" ]; then
    echo -e "${GREEN}✓ Custom UI Style was installed before Islands Dark - leaving it installed${NC}"
    echo "   The Islands Dark CSS rules have been removed from your settings."
else
    if [ "$HAS_CLI" = true ]; then
        code --uninstall-extension subframe7536.custom-ui-style --force 2>/dev/null && \
            echo -e "${GREEN}✓ Custom UI Style extension uninstalled${NC}" || \
            echo -e "${YELLOW}⚠️  Custom UI Style may already be removed${NC}"
    else
        echo -e "${YELLOW}⚠️  Please uninstall Custom UI Style manually from VS Code Extensions${NC}"
    fi
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

# Step 6: Reload VS Code
echo ""
echo "🔄 Step 6: Reloading VS Code..."

if [ "$HAS_CLI" = true ]; then
    code --reload-window 2>/dev/null || code . 2>/dev/null || true
    echo -e "${GREEN}✓ VS Code reload triggered${NC}"
else
    echo -e "${YELLOW}⚠️  Please restart VS Code manually to complete the uninstall${NC}"
fi

echo ""
echo -e "${GREEN}✓ Islands Dark has been uninstalled!${NC}"
echo ""
echo -e "${YELLOW}Note: If you see CSS artifacts, open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)${NC}"
echo -e "${YELLOW}and run 'Custom UI Style: Disable' to clean up injected styles.${NC}"
echo ""
