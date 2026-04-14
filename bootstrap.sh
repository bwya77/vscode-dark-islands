#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/bwya77/vscode-dark-islands.git"
BRANCH="main"
INSTALL_DIR="${TMPDIR:-/tmp}/islands-dark-temp"

echo "Downloading Islands Dark..."
rm -rf "$INSTALL_DIR"
git clone "$REPO_URL" "$INSTALL_DIR" --quiet --branch "$BRANCH"

echo "Running installer..."
"$INSTALL_DIR/install.sh"

echo "Temporary files kept at: $INSTALL_DIR"
