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
CSS_URL="$(file_url "$SCRIPT_DIR/custom-css/islands-dark.css")"

if [ -d "$EXTENSION_DIR" ] || [ -L "$EXTENSION_DIR" ]; then
  rm -rf "$EXTENSION_DIR"
  echo "Removed native Islands Dark color theme from $EXTENSION_DIR."
else
  echo "Native Islands Dark color theme folder was not found at $EXTENSION_DIR."
fi

echo ""
echo "Finish manually:"
echo "1. Run Command Palette > Disable Custom CSS and JS to restore VS Code's patched workbench file."
echo "2. Remove this URL from vscode_custom_css.imports in settings.json:"
echo "   $CSS_URL"
echo "3. Change to another color theme if VS Code is still using Islands Dark."
