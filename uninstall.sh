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

# Step 4: Remove extension from extensions.json
echo ""
echo "📋 Step 4: Unregistering extension..."
if command -v node &> /dev/null; then
    node << 'UNREGISTER_SCRIPT'
const fs = require('fs');
const path = require('path');

const extJsonPath = path.join(process.env.HOME, '.vscode', 'extensions', 'extensions.json');
if (fs.existsSync(extJsonPath)) {
    try {
        let extensions = JSON.parse(fs.readFileSync(extJsonPath, 'utf8'));
        const before = extensions.length;
        extensions = extensions.filter(e =>
            e.identifier?.id !== 'bwya77.islands-dark' &&
            e.identifier?.id !== 'your-publisher-name.islands-dark'
        );
        if (extensions.length < before) {
            fs.writeFileSync(extJsonPath, JSON.stringify(extensions));
            console.log('Extension unregistered');
        } else {
            console.log('Extension was not registered');
        }
    } catch (e) {
        console.log('Could not update extensions.json');
    }
}
UNREGISTER_SCRIPT
    echo -e "${GREEN}✓ Extension unregistered${NC}"
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
