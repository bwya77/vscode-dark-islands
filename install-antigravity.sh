#!/bin/bash

set -e

echo "Islands Dark Theme Installer for Antigravity"
echo "============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Check if Antigravity is installed by looking for the .gemini/antigravity directory
AG_DIR="$HOME/.gemini/antigravity"
if [ ! -d "$AG_DIR" ]; then
    echo -e "${RED}Error: Antigravity directory not found!${NC}"
    echo "Expected location: $AG_DIR"
    echo "Please ensure Antigravity is installed and has been run at least once."
    exit 1
fi

echo -e "${GREEN}Antigravity installation found${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "Step 1: Installing Islands Dark theme extension..."

# Antigravity on macOS uses ~/.antigravity/extensions/
AG_EXT_DIR="$HOME/.antigravity/extensions"
EXT_DIR="$AG_EXT_DIR/bwya77.islands-dark-1.0.0"
rm -rf "$EXT_DIR"
mkdir -p "$EXT_DIR"
cp "$SCRIPT_DIR/package.json" "$EXT_DIR/"
cp -r "$SCRIPT_DIR/themes" "$EXT_DIR/"

if [ -d "$EXT_DIR/themes" ]; then
    echo -e "${GREEN}Theme extension installed to $EXT_DIR${NC}"
else
    echo -e "${RED}Failed to install theme extension${NC}"
    exit 1
fi

# Remove extensions.json so Antigravity rebuilds it cleanly
EXT_JSON="$AG_EXT_DIR/extensions.json"
if [ -f "$EXT_JSON" ]; then
    rm -f "$EXT_JSON"
    echo -e "${GREEN}Cleared extensions.json (will be rebuilt on next launch)${NC}"
fi

echo ""
echo "Step 2: Installing Custom UI Style extension..."
echo -e "${GRAY}   Note: Antigravity supports VS Code extensions${NC}"

if command -v code &> /dev/null; then
    if code --install-extension subframe7536.custom-ui-style --force 2>&1; then
        echo -e "${GREEN}Custom UI Style extension installed${NC}"
    else
        echo -e "${YELLOW}Could not install Custom UI Style extension automatically${NC}"
        echo "   Please install it manually from the Extensions marketplace in Antigravity"
    fi
else
    echo -e "${YELLOW}Could not install Custom UI Style extension automatically${NC}"
    echo "   Please install 'Custom UI Style' (by subframe7536) manually from the Extensions marketplace in Antigravity"
fi

echo ""
echo "Step 3: Installing Bear Sans UI fonts..."
FONT_DIR="$HOME/Library/Fonts"
echo "   Installing fonts to: $FONT_DIR"
cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
echo -e "${GREEN}Fonts installed${NC}"
echo "   Note: You may need to restart applications to use the new fonts"

echo ""
echo "Step 4: Installing editor fonts..."

IBM_INSTALLED=false
FIRA_INSTALLED=false

# Check if fonts are already installed via Font Book
if ls ~/Library/Fonts/IBMPlexMono-* &>/dev/null; then
    echo -e "${GREEN}IBM Plex Mono already installed${NC}"
    IBM_INSTALLED=true
fi
if ls ~/Library/Fonts/FiraCodeNerdFontMono-* &>/dev/null; then
    echo -e "${GREEN}FiraCode Nerd Font Mono already installed${NC}"
    FIRA_INSTALLED=true
fi

# Try Homebrew for missing fonts
if ! $IBM_INSTALLED || ! $FIRA_INSTALLED; then
    if command -v brew &>/dev/null; then
        if ! $IBM_INSTALLED; then
            echo "   Installing IBM Plex Mono via Homebrew..."
            brew install --cask font-ibm-plex-mono 2>/dev/null && echo -e "${GREEN}IBM Plex Mono installed${NC}" || echo -e "${YELLOW}Could not install IBM Plex Mono${NC}"
        fi
        if ! $FIRA_INSTALLED; then
            echo "   Installing FiraCode Nerd Font Mono via Homebrew..."
            brew install --cask font-fira-code-nerd-font 2>/dev/null && echo -e "${GREEN}FiraCode Nerd Font Mono installed${NC}" || echo -e "${YELLOW}Could not install FiraCode Nerd Font Mono${NC}"
        fi
    else
        echo -e "${YELLOW}Homebrew not found. Please install manually:${NC}"
        ! $IBM_INSTALLED && echo "   - IBM Plex Mono: https://fonts.google.com/specimen/IBM+Plex+Mono"
        ! $FIRA_INSTALLED && echo "   - FiraCode Nerd Font: brew install --cask font-fira-code-nerd-font"
    fi
fi

echo ""
echo "Step 5: Applying Antigravity settings..."

# Antigravity settings on macOS: try Antigravity-specific dir first,
# fall back to Code/ (shared with VS Code), else create Antigravity dir
AG_CODE_DIR="$HOME/Library/Application Support/Antigravity/User"
VSCODE_DIR="$HOME/Library/Application Support/Code/User"

# Prefer Antigravity-specific directory. Even if it doesn't exist yet,
# it will be created when Antigravity restarts, so copy settings there.
SETTINGS_DIR="$AG_CODE_DIR"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Create settings directory if it doesn't exist
if [ ! -d "$SETTINGS_DIR" ]; then
    echo -e "${YELLOW}Creating Antigravity settings directory...${NC}"
    mkdir -p "$SETTINGS_DIR"
fi

if [ -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}Existing settings.json found at: $SETTINGS_FILE${NC}"
    echo "   Backing up to settings.json.pre-islands-dark"
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.pre-islands-dark"

    # Use Python to merge settings (Python is pre-installed on macOS)
    set +e
    python3 - "$SETTINGS_FILE" "$SCRIPT_DIR/settings.json" "$SETTINGS_FILE" <<'PYEOF'
import sys, json, re

def strip_jsonc(text):
    result = []
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        if ch == '"':
            j = i + 1
            while j < n:
                if text[j] == '\\':
                    j += 2
                elif text[j] == '"':
                    j += 1
                    break
                else:
                    j += 1
            result.append(text[i:j])
            i = j
        elif ch == '/' and i + 1 < n and text[i+1] == '/':
            j = text.index('\n', i) if '\n' in text[i:] else n
            i = j
        elif ch == '/' and i + 1 < n and text[i+1] == '*':
            j = text.index('*/', i + 2) + 2
            i = j
        else:
            result.append(ch)
            i += 1
    cleaned = ''.join(result)
    cleaned = re.sub(r',\s*([}\]])', r'\1', cleaned)
    return cleaned

def deep_merge(base, override):
    result = {}
    for key in base:
        result[key] = base[key]
    for key in override:
        if key in result and isinstance(result[key], dict) and isinstance(override[key], dict):
            result[key] = deep_merge(result[key], override[key])
        else:
            result[key] = override[key]
    return result

existing_path = sys.argv[1]
new_path = sys.argv[2]
output_path = sys.argv[3]

with open(existing_path, 'r') as f:
    existing = json.loads(strip_jsonc(f.read()))

with open(new_path, 'r') as f:
    new = json.loads(strip_jsonc(f.read()))

merged = deep_merge(existing, new)

with open(output_path, 'w') as f:
    json.dump(merged, f, indent=4)
    f.write('\n')

print("OK")
PYEOF
    ret=$?
    set -e

    if [ $ret -eq 0 ]; then
        echo -e "${GREEN}Settings merged successfully${NC}"
    else
        # If Python merge fails (e.g. old settings.json is not valid JSON),
        # copy the Islands Dark settings directly (backup was made above)
        cp "$SCRIPT_DIR/settings.json" "$SETTINGS_FILE"
        echo -e "${YELLOW}Could not merge settings automatically${NC}"
        echo "   Islands Dark settings applied directly (your old settings are backed up)"
        echo "   You can manually merge from settings.json.pre-islands-dark"
    fi
else
    cp "$SCRIPT_DIR/settings.json" "$SETTINGS_FILE"
    echo -e "${GREEN}Settings applied to: $SETTINGS_FILE${NC}"
fi

echo ""
echo "Step 6: Enabling Custom UI Style..."

# Check if this is the first run
FIRST_RUN_FILE="$SCRIPT_DIR/.islands_dark_first_run_antigravity"
if [ ! -f "$FIRST_RUN_FILE" ]; then
    touch "$FIRST_RUN_FILE"
    echo ""
    echo -e "${YELLOW}Important Notes:${NC}"
    echo "   - IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    echo "   - After Antigravity reloads, you may see a 'corrupt installation' warning"
    echo "   - This is expected when using custom CSS - click the gear icon and select 'Don't Show Again'"
    echo "   - To activate the theme, use the theme picker (Cmd+K Cmd+T)"
    echo ""
    if [ -t 0 ]; then
        read -p "Press Enter to continue..."
    fi
fi

echo "   Applying CSS customizations..."
echo ""
echo -e "${GREEN}Islands Dark theme has been installed for Antigravity!${NC}"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo "   1. Restart Antigravity to apply the changes"
echo "   2. Open the Command Palette (Cmd+Shift+P)"
echo "   3. Type 'Color Theme' and select 'Preferences: Color Theme'"
echo "   4. Select 'Islands Dark' from the list"
echo "   5. If you see a warning about corrupt installation, click 'Don't Show Again'"
echo ""
echo -e "${GRAY}Settings file location: $SETTINGS_FILE${NC}"
echo ""
echo -e "${GREEN}Done!${NC}"
