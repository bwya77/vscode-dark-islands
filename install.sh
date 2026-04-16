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

echo "Islands Dark minimal installer"
echo "This installs only the native color theme helper and prints the manual CSS setup."
echo ""

echo "Installing native Islands Dark color theme to $EXTENSION_DIR..."
rm -rf "$EXTENSION_DIR"
mkdir -p "$EXTENSION_DIR"
cp "$SCRIPT_DIR/package.json" "$EXTENSION_DIR/"
cp -R "$SCRIPT_DIR/themes" "$EXTENSION_DIR/"

if command -v code >/dev/null 2>&1; then
  echo "Installing Custom CSS and JS Loader..."
  if ! code --install-extension be5invis.vscode-custom-css --force; then
    echo "Could not install Custom CSS and JS Loader automatically. Install it manually from VS Code Extensions." >&2
  fi
else
  echo "VS Code CLI 'code' was not found. Install Custom CSS and JS Loader manually." >&2
fi

echo ""
echo "Theme helper installed. Finish manually:"
echo "1. Install the .otf files from ./fonts if you want the exact typography."
echo "2. Add this to VS Code settings.json:"
echo ""
echo "   \"workbench.colorTheme\": \"Islands Dark\","
echo "   \"vscode_custom_css.statusbar\": true,"
echo "   \"vscode_custom_css.imports\": ["
echo "     \"$CSS_URL\""
echo "   ]"
echo ""
echo "3. Run Command Palette > Enable Custom CSS and JS, or Reload Custom CSS and JS."
echo "4. Reload VS Code."
echo ""
echo "This script did not edit settings.json or install fonts."
