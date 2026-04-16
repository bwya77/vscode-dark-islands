#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/bwya77/vscode-dark-islands.git"
BRANCH="main"
INSTALL_DIR="$HOME/vscode-dark-islands"

if [ -d "$INSTALL_DIR/.git" ]; then
  echo "Updating Islands Dark at $INSTALL_DIR..."
  git -C "$INSTALL_DIR" pull --ff-only
elif [ -e "$INSTALL_DIR" ]; then
  echo "Install directory already exists but is not a git checkout: $INSTALL_DIR" >&2
  exit 1
else
  echo "Downloading Islands Dark to $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR" --quiet --branch "$BRANCH"
fi

echo "Running installer..."
"$INSTALL_DIR/install.sh"

echo "Keep this folder in place. The CSS import points to it: $INSTALL_DIR"
