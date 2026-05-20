#!/bin/bash
#
# Islands Dark Theme Installer for Antigravity / Antigravity IDE (macOS)
# https://github.com/bwya77/vscode-dark-islands
#
# Installs the Islands Dark color theme + Custom UI Style CSS customizations
# into Google's Antigravity AI IDE (a VS Code fork).
#
# Detects both:
#   - Antigravity IDE (~/.antigravity-ide)
#   - Antigravity (~/.antigravity, ~/Library/Application Support/Antigravity)

set -e

echo ""
echo "  Islands Dark Theme Installer for Antigravity"
echo "  ============================================="
echo ""

# -------------------------------------------------------------------
# Colors
# -------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# -------------------------------------------------------------------
# Detect Antigravity installations
# -------------------------------------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

AG_INSTALLS=()

# Antigravity IDE (newer, uses ~/.antigravity-ide)
if [ -d "$HOME/.antigravity-ide" ]; then
    AG_INSTALLS+=("$HOME/.antigravity-ide/extensions|$HOME/.antigravity-ide/User|Antigravity IDE")
    echo -e "${GREEN}Found: Antigravity IDE${NC}"
fi

# Antigravity (older, uses ~/.antigravity)
if [ -d "$HOME/.antigravity" ]; then
    AG_INSTALLS+=("$HOME/.antigravity/extensions|$HOME/Library/Application Support/Antigravity/User|Antigravity")
    echo -e "${GREEN}Found: Antigravity${NC}"
fi

# Fallback: check for .gemini/antigravity directory
if [ ${#AG_INSTALLS[@]} -eq 0 ] && [ -d "$HOME/.gemini/antigravity" ]; then
    AG_INSTALLS+=("$HOME/.antigravity/extensions|$HOME/Library/Application Support/Antigravity/User|Antigravity (gemini)")
    echo -e "${GREEN}Found: Antigravity (via .gemini)${NC}"
fi

if [ ${#AG_INSTALLS[@]} -eq 0 ]; then
    echo -e "${YELLOW}No Antigravity installation detected.${NC}"
    echo "  Expected: ~/.antigravity-ide or ~/.antigravity"
    echo "  Please run Antigravity at least once before installing."
    echo ""
    echo "  Continuing anyway to install shared components..."
    echo ""
fi

# -------------------------------------------------------------------
# Step 1: Install Islands Dark theme extension
# -------------------------------------------------------------------
echo ""
echo "Step 1: Installing Islands Dark theme extension..."

EXT_DIR_NAME="bwya77.islands-dark-1.0.0"

install_theme() {
    local extensions_dir="$1"
    local label="$2"
    local dest="$extensions_dir/$EXT_DIR_NAME"

    echo "  Installing to: $dest"
    rm -rf "$dest"
    mkdir -p "$dest"
    cp "$SCRIPT_DIR/package.json" "$dest/"
    cp -r "$SCRIPT_DIR/themes" "$dest/"

    if [ -d "$dest/themes" ]; then
        echo -e "  ${GREEN}Theme extension installed for $label${NC}"
    else
        echo -e "  ${RED}Failed to install theme for $label${NC}"
        return 1
    fi

    # Clean extensions.json so it gets rebuilt
    local ext_json="$extensions_dir/extensions.json"
    if [ -f "$ext_json" ]; then
        rm -f "$ext_json"
    fi

    # Also clean old backups that might interfere
    rm -f "$extensions_dir/extensions.json.backup" 2>/dev/null || true
}

for install in "${AG_INSTALLS[@]}"; do
    IFS='|' read -r ext_dir _ label <<< "$install"
    install_theme "$ext_dir" "$label" || true
done

# Always install to shared ~/.vscode as fallback
if [ -d "$HOME/.vscode/extensions" ]; then
    install_theme "$HOME/.vscode/extensions" "VS Code shared" || true
fi

# -------------------------------------------------------------------
# Step 2: Install Custom UI Style extension
# -------------------------------------------------------------------
echo ""
echo "Step 2: Installing Custom UI Style extension..."

CUSTOM_UI_NS="subframe7536"
CUSTOM_UI_NAME="custom-ui-style"

install_custom_ui() {
    local extensions_dir="$1"
    local label="$2"

    # Try to get the latest version from Open VSX
    local api_resp
    api_resp=$(curl -s "https://open-vsx.org/api/${CUSTOM_UI_NS}/${CUSTOM_UI_NAME}/latest" 2>/dev/null || echo "")
    local version download_url
    version=$(echo "$api_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('version',''))" 2>/dev/null || echo "")
    download_url=$(echo "$api_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('files',{}).get('download',''))" 2>/dev/null || echo "")

    if [ -z "$version" ] || [ -z "$download_url" ]; then
        echo -e "  ${YELLOW}Could not fetch Custom UI Style from Open VSX for $label${NC}"
        return 1
    fi

    local dest_dir="$extensions_dir/${CUSTOM_UI_NS}.${CUSTOM_UI_NAME}-${version}"
    if [ -d "$dest_dir" ] && [ -f "$dest_dir/package.json" ]; then
        echo "  Custom UI Style v$version already installed for $label"
        echo "$version" > "/tmp/cus_version.txt"
        return 0
    fi

    local vsix_path="/tmp/${CUSTOM_UI_NS}.${CUSTOM_UI_NAME}-${version}.vsix"
    echo "  Downloading Custom UI Style v$version for $label..."
    curl -sL -o "$vsix_path" "$download_url"

    if [ ! -f "$vsix_path" ]; then
        echo -e "  ${YELLOW}Download failed for $label${NC}"
        return 1
    fi

    mkdir -p "$dest_dir"
    unzip -qo "$vsix_path" -d "$dest_dir"
    rm -f "$vsix_path"

    # Some VSIX have content inside extension/ subfolder
    if [ -d "$dest_dir/extension" ] && [ ! -f "$dest_dir/package.json" ]; then
        mv "$dest_dir/extension"/* "$dest_dir/" 2>/dev/null || true
        rmdir "$dest_dir/extension" 2>/dev/null || true
    fi

    if [ -f "$dest_dir/package.json" ]; then
        echo -e "  ${GREEN}Custom UI Style v$version installed for $label${NC}"
        rm -f "$extensions_dir/extensions.json"
        echo "$version" > "/tmp/cus_version.txt"
        return 0
    else
        echo -e "  ${RED}Failed to extract Custom UI Style for $label${NC}"
        return 1
    fi
}

for install in "${AG_INSTALLS[@]}"; do
    IFS='|' read -r ext_dir _ label <<< "$install"
    install_custom_ui "$ext_dir" "$label" || true
done

if [ -d "$HOME/.vscode/extensions" ]; then
    install_custom_ui "$HOME/.vscode/extensions" "VS Code shared" || true
fi

CUS_VERSION=$(cat /tmp/cus_version.txt 2>/dev/null || echo "0.7.0")
rm -f /tmp/cus_version.txt

# -------------------------------------------------------------------
# Step 3: Install fonts
# -------------------------------------------------------------------
echo ""
echo "Step 3: Installing Bear Sans UI fonts..."

FONT_DIR="$HOME/Library/Fonts"
if ! ls "$FONT_DIR/BearSansUI-Regular.otf" &>/dev/null; then
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    echo -e "  ${GREEN}Bear Sans UI fonts installed${NC}"
else
    echo -e "  ${GREEN}Bear Sans UI fonts already installed${NC}"
fi

echo ""
echo "Step 4: Installing editor fonts..."

IBM_INSTALLED=false
FIRA_INSTALLED=false

if ls "$FONT_DIR/IBMPlexMono-"* &>/dev/null 2>&1; then
    echo -e "  ${GREEN}IBM Plex Mono already installed${NC}"
    IBM_INSTALLED=true
fi
if ls "$FONT_DIR/FiraCodeNerdFontMono-"* &>/dev/null 2>&1; then
    echo -e "  ${GREEN}FiraCode Nerd Font Mono already installed${NC}"
    FIRA_INSTALLED=true
fi

if ! $IBM_INSTALLED || ! $FIRA_INSTALLED; then
    if command -v brew &>/dev/null; then
        ! $IBM_INSTALLED && brew install --cask font-ibm-plex-mono 2>/dev/null && echo -e "  ${GREEN}IBM Plex Mono installed${NC}" || echo -e "  ${YELLOW}Could not install IBM Plex Mono${NC}"
        ! $FIRA_INSTALLED && brew install --cask font-fira-code-nerd-font 2>/dev/null && echo -e "  ${GREEN}FiraCode Nerd Font installed${NC}" || echo -e "  ${YELLOW}Could not install FiraCode Nerd Font${NC}"
    else
        echo -e "  ${YELLOW}Homebrew not found. Please install manually:${NC}"
        ! $IBM_INSTALLED && echo "    - IBM Plex Mono: https://fonts.google.com/specimen/IBM+Plex+Mono"
        ! $FIRA_INSTALLED && echo "    - FiraCode Nerd Font: brew install --cask font-fira-code-nerd-font"
    fi
fi

# -------------------------------------------------------------------
# Step 5: Apply settings
# -------------------------------------------------------------------
echo ""
echo "Step 5: Applying settings..."

apply_settings() {
    local user_dir="$1"
    local label="$2"
    local settings_file="$user_dir/settings.json"

    mkdir -p "$user_dir"

    if [ -f "$settings_file" ]; then
        echo "  Existing settings found for $label"
        cp "$settings_file" "$settings_file.pre-islands-dark"
        echo "  Backed up to: $settings_file.pre-islands-dark"

        set +e
        python3 - "$settings_file" "$SCRIPT_DIR/settings.json" "$settings_file" <<'PYEOF'
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
                if text[j] == '\\': j += 2
                elif text[j] == '"': j += 1; break
                else: j += 1
            result.append(text[i:j]); i = j
        elif ch == '/' and i + 1 < n and text[i+1] == '/':
            j = text.index('\n', i) if '\n' in text[i:] else n; i = j
        elif ch == '/' and i + 1 < n and text[i+1] == '*':
            j = text.index('*/', i + 2) + 2; i = j
        else:
            result.append(ch); i += 1
    cleaned = ''.join(result)
    cleaned = re.sub(r',\s*([}\]])', r'\1', cleaned)
    return cleaned

def merge(base, override):
    result = dict(base)
    for k, v in override.items():
        if k in result and isinstance(result[k], dict) and isinstance(v, dict):
            result[k] = merge(result[k], v)
        else:
            result[k] = v
    return result

existing_path, new_path, output_path = sys.argv[1], sys.argv[2], sys.argv[3]

with open(existing_path) as f:
    existing = json.loads(strip_jsonc(f.read()))
with open(new_path) as f:
    new = json.loads(strip_jsonc(f.read()))

merged = merge(existing, new)

with open(output_path, 'w') as f:
    json.dump(merged, f, indent=4)
    f.write('\n')
print("OK")
PYEOF
        ret=$?
        set -e

        if [ $ret -eq 0 ]; then
            echo -e "  ${GREEN}Settings merged for $label${NC}"
        else
            cp "$SCRIPT_DIR/settings.json" "$settings_file"
            echo -e "  ${YELLOW}Could not merge. Applied directly (backup saved)${NC}"
        fi
    else
        cp "$SCRIPT_DIR/settings.json" "$settings_file"
        echo -e "  ${GREEN}Settings applied to $label${NC}"
    fi
}

for install in "${AG_INSTALLS[@]}"; do
    IFS='|' read -r _ user_dir label <<< "$install"
    apply_settings "$user_dir" "$label"
done

# -------------------------------------------------------------------
# Step 6: Patch Custom UI Style extension
# -------------------------------------------------------------------
echo ""
echo "Step 6: Patching Custom UI Style extension..."

patch_extension() {
    local ext_dir="$1"
    local label="$2"
    local dist_dir="$ext_dir/${CUSTOM_UI_NS}.${CUSTOM_UI_NAME}-${CUS_VERSION}"
    local dist_file="$dist_dir/dist/index.js"

    if [ ! -f "$dist_file" ]; then
        # Try to find any version
        dist_file=$(ls "$ext_dir/${CUSTOM_UI_NS}.${CUSTOM_UI_NAME}-"*/dist/index.js 2>/dev/null | head -1)
    fi

    if [ ! -f "$dist_file" ]; then
        echo -e "  ${YELLOW}Custom UI Style not found for $label, skipping patch${NC}"
        return
    fi

    # Backup original
    if [ ! -f "$dist_file.orig" ]; then
        cp "$dist_file" "$dist_file.orig"
    fi

    # Generate CSS from settings.json and embed it directly into the extension code.
    # We must bypass reactive-vscode because config refs return empty outside
    # the Vue effect scope during patch().
    python3 - "$dist_file" "$SCRIPT_DIR/settings.json" <<'PYEOF'
import sys, json

dist_file = sys.argv[1]
settings_file = sys.argv[2]

# Read the stylesheet from the Islands Dark settings
with open(settings_file) as f:
    raw = f.read()

# Strip JSONC
import re
raw_clean = re.sub(r'//.*$', '', raw, flags=re.MULTILINE)
raw_clean = re.sub(r'/\*[\s\S]*?\*/', '', raw_clean)
raw_clean = re.sub(r',\s*([}\]])', r'\1', raw_clean)
settings = json.loads(raw_clean)

stylesheet = settings.get('custom-ui-style.stylesheet', {})

# Generate flat CSS (same algorithm as Custom UI Style's generateStyleFromObject)
def gen(obj, styles=''):
    result = styles
    for prop, value in obj.items():
        if isinstance(value, str):
            result += prop + ':' + value + ';'
        elif isinstance(value, (int, float)):
            result += prop + ':' + str(value) + ';'
        elif isinstance(value, dict) and value:
            result += prop + '{' + gen(value) + '}'
    return result

css = ''
for selectors, val in stylesheet.items():
    if isinstance(val, str):
        c = val
    elif isinstance(val, dict):
        c = gen(val)
    else:
        continue
    css += selectors + '{' + c + '}'

print(f"  Generated {len(css)} bytes of CSS from {len(stylesheet)} selectors")

# Read the extension code
with open(dist_file) as f:
    content = f.read()

# Replace F.stylesheet with the CSS embedded inline
old = "F.stylesheet"
# Escape CSS for JS string literal
css_escaped = css.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
css_escaped = css_escaped.replace('\t', '\\t')

new_patch = 'patch(e){return e+"\\n/* Custom UI Style Start */\\n' + css_escaped + '\\n/* Custom UI Style End */\\n"}'
old_patch = 'patch(e){return zr(e,F.stylesheet)}'

if old_patch in content:
    content = content.replace(old_patch, new_patch)
    print(f"  Patched patch() method ({len(new_patch)} chars)")
else:
    print(f"  WARNING: Could not find patch method pattern. Extension version may differ.")
    # Try alternative: replace F.stylesheet with JSON.parse(readFileSync(...))
    if old in content:
        new = 'JSON.parse(require("fs").readFileSync(require("os").homedir()+' + "'/.antigravity-ide/islands-custom.json','utf8'))"
        content = content.replace(old, new)
        print(f"  Fallback: replaced F.stylesheet with file read")

# Also fix other reactive-vscode refs (F.preferRestart, etc.)
for r_old, r_new in [
    ('F.preferRestart', 'false'),
    ("F[`external.imports`]", '[]'),
    ("F[`external.loadStrategy`]", "'refetch'"),
]:
    if r_old in content:
        content = content.replace(r_old, r_new)

with open(dist_file, 'w') as f:
    f.write(content)

print(f"  Patched: {dist_file}")
PYEOF

    echo -e "  ${GREEN}Custom UI Style patched for $label${NC}"
}

for install in "${AG_INSTALLS[@]}"; do
    IFS='|' read -r ext_dir _ label <<< "$install"
    patch_extension "$ext_dir" "$label"
done

# -------------------------------------------------------------------
# Done
# -------------------------------------------------------------------
echo ""
echo "====================================================="
echo -e "${GREEN}  Islands Dark installed for Antigravity!${NC}"
echo ""
echo -e "${CYAN}  Next Steps:${NC}"
echo "    1. Cmd+Q to fully quit Antigravity"
echo "    2. Open Antigravity again"
echo "    3. Cmd+Shift+P -> 'Preferences: Color Theme' -> 'Islands Dark'"
echo "    4. If you see 'corrupt installation' warning, click 'Don't Show Again'"
echo ""
echo -e "${GRAY}  Theme extension: ~/.antigravity-ide/extensions/bwya77.islands-dark-1.0.0/${NC}"
echo ""
echo "Done!"
echo ""
