#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
INSTALLED_CSS_URL="$(file_url "$EXTENSION_DIR/custom-css/islands-dark.css")"
REPO_CSS_URL="$(file_url "$SCRIPT_DIR/custom-css/islands-dark.css")"

if [ "${OSTYPE:-}" = "darwin" ] || [[ "${OSTYPE:-}" == darwin* ]]; then
  SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
else
  SETTINGS_DIR="$HOME/.config/Code/User"
fi
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

if [ -f "$SETTINGS_FILE" ] && command -v node >/dev/null 2>&1; then
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.pre-islands-dark-uninstall"
  node - "$SETTINGS_FILE" "$INSTALLED_CSS_URL" "$REPO_CSS_URL" <<'NODE'
const fs = require('fs');
const [settingsFile, ...cssUrls] = process.argv.slice(2);
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
const raw = fs.readFileSync(settingsFile, 'utf8').trim();
const settings = raw ? JSON.parse(stripJsonc(raw)) : {};
if (Array.isArray(settings['vscode_custom_css.imports'])) {
  settings['vscode_custom_css.imports'] = settings['vscode_custom_css.imports'].filter(x => !cssUrls.includes(x));
}
fs.writeFileSync(settingsFile, JSON.stringify(settings, null, 2));
NODE
  echo "Removed Islands Dark CSS import from settings.json."
elif [ -f "$SETTINGS_FILE" ]; then
  echo "Node.js was not found, so settings.json was not modified automatically."
  echo "Remove these entries from vscode_custom_css.imports if present:"
  echo "  $INSTALLED_CSS_URL"
  echo "  $REPO_CSS_URL"
fi

echo ""
echo "Run Command Palette > Disable Custom CSS and JS to restore VS Code's patched workbench file."
echo "Then uninstall the Islands Dark extension normally if desired."
