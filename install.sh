#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v code >/dev/null 2>&1; then
  echo "VS Code CLI 'code' was not found. Install VS Code or add the code command to PATH." >&2
  exit 1
fi

read_package_value() {
  sed -nE "s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\"([^\"]+)\".*/\1/p" "$SCRIPT_DIR/package.json" | head -n 1
}

file_url() {
  local path="$1"
  local encoded=""
  local i ch hex

  LC_ALL=C
  for ((i = 0; i < ${#path}; i++)); do
    ch="${path:i:1}"
    case "$ch" in
      [a-zA-Z0-9.~_/-]) encoded+="$ch" ;;
      *) printf -v hex '%%%02X' "'$ch"; encoded+="$hex" ;;
    esac
  done

  printf 'file://%s\n' "$encoded"
}

PUBLISHER="$(read_package_value publisher)"
NAME="$(read_package_value name)"
VERSION="$(read_package_value version)"
if [ -z "$PUBLISHER" ] || [ -z "$NAME" ] || [ -z "$VERSION" ]; then
  echo "Could not read extension metadata from package.json." >&2
  exit 1
fi
EXTENSION_DIR="$HOME/.vscode/extensions/$PUBLISHER.$NAME-$VERSION"

echo "Islands Dark installer"
echo "This installs the theme, Custom CSS and JS Loader, fonts, and prepares the CSS import setting."
echo "When Node.js is available, it merges settings instead of replacing your settings.json."
echo ""

echo "Installing Islands Dark theme extension to $EXTENSION_DIR..."
rm -rf "$EXTENSION_DIR"
mkdir -p "$EXTENSION_DIR"
for item in package.json README.md themes custom-css assets fonts icon.png; do
  if [ -e "$SCRIPT_DIR/$item" ]; then
    cp -R "$SCRIPT_DIR/$item" "$EXTENSION_DIR/"
  fi
done

echo "Installing Custom CSS and JS Loader..."
code --install-extension be5invis.vscode-custom-css --force

echo "Installing bundled Bear Sans UI fonts..."
case "${OSTYPE:-}" in
  darwin*)
    FONT_DIR="$HOME/Library/Fonts"
    mkdir -p "$FONT_DIR"
    cp "$SCRIPT_DIR"/fonts/*.otf "$FONT_DIR"/ 2>/dev/null || true
    ;;
  linux*)
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    cp "$SCRIPT_DIR"/fonts/*.otf "$FONT_DIR"/ 2>/dev/null || true
    fc-cache -f >/dev/null 2>&1 || true
    ;;
  *)
    echo "Skipping automatic font install for this OS. Install fonts from ./fonts manually."
    ;;
esac

if [[ "${OSTYPE:-}" == darwin* ]]; then
  SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
else
  SETTINGS_DIR="$HOME/.config/Code/User"
fi
mkdir -p "$SETTINGS_DIR"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
CSS_URL="$(file_url "$EXTENSION_DIR/custom-css/islands-dark.css")"

if [ -f "$SETTINGS_FILE" ] && command -v node >/dev/null 2>&1; then
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.pre-islands-dark"
  echo "Backed up settings to $SETTINGS_FILE.pre-islands-dark"
fi

if command -v node >/dev/null 2>&1; then
  node - "$SETTINGS_FILE" "$CSS_URL" <<'NODE'
const fs = require('fs');
const [settingsFile, cssUrl] = process.argv.slice(2);
function stripJsonc(text) {
  let output = '';
  let inString = false;
  let escaped = false;
  let lineComment = false;
  let blockComment = false;

  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    const next = text[i + 1] || '';

    if (lineComment) {
      if (ch === '\n') {
        lineComment = false;
        output += ch;
      }
      continue;
    }
    if (blockComment) {
      if (ch === '*' && next === '/') {
        blockComment = false;
        i++;
      }
      continue;
    }
    if (inString) {
      output += ch;
      if (escaped) escaped = false;
      else if (ch === '\\') escaped = true;
      else if (ch === '"') inString = false;
      continue;
    }
    if (ch === '"') {
      inString = true;
      output += ch;
      continue;
    }
    if (ch === '/' && next === '/') {
      lineComment = true;
      i++;
      continue;
    }
    if (ch === '/' && next === '*') {
      blockComment = true;
      i++;
      continue;
    }
    output += ch;
  }

  return output.replace(/,\s*([}\]])/g, '$1');
}
let settings = {};
if (fs.existsSync(settingsFile)) {
  const raw = fs.readFileSync(settingsFile, 'utf8').trim();
  if (raw) settings = JSON.parse(stripJsonc(raw));
}
const imports = Array.isArray(settings['vscode_custom_css.imports'])
  ? settings['vscode_custom_css.imports']
  : [];
if (!imports.includes(cssUrl)) imports.push(cssUrl);
settings['vscode_custom_css.imports'] = imports;
settings['vscode_custom_css.statusbar'] = true;
settings['workbench.colorTheme'] = 'Islands Dark';
fs.writeFileSync(settingsFile, JSON.stringify(settings, null, 2));
NODE
  SETTINGS_UPDATED=1
else
  SETTINGS_UPDATED=0
fi

echo ""
echo "Installed. Final step:"
if [ "$SETTINGS_UPDATED" -eq 0 ]; then
  echo "Node.js was not found, so settings.json was not modified automatically."
  echo "Add these settings in VS Code before enabling the custom CSS loader:"
  echo "If vscode_custom_css.imports already exists, add the CSS URL to that existing array."
  echo ""
  echo "\"workbench.colorTheme\": \"Islands Dark\","
  echo "\"vscode_custom_css.statusbar\": true,"
  echo "\"vscode_custom_css.imports\": ["
  echo "  \"$CSS_URL\""
  echo "]"
  echo ""
fi
echo "1. Restart VS Code with permission to modify its install directory if needed."
echo "2. Run Command Palette > Enable Custom CSS and JS, or Reload Custom CSS and JS."
echo "3. Reload VS Code."
echo ""
if [ "$SETTINGS_UPDATED" -eq 1 ]; then
  echo "CSS import added: $CSS_URL"
else
  echo "CSS import URL: $CSS_URL"
fi
