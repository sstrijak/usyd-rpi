#!/usr/bin/env bash

set -e

# ==========================================
# Configuration
# ==========================================
SSH_KEY_PATH="$HOME/.ssh/usyd-rpi.ro@github.com" # Path to your private deploy key
REPO_URL="git@github.com:sstrijak/usyd-rpi.git"  # SSH URL of the repository
TARGET_DIR="${1:-usyd-rpi}"                      # Clone directory (defaults to 'usyd-rpi')

# ==========================================
# Validation & Setup
# ==========================================
if [[ ! -f "$SSH_KEY_PATH" ]]; then
  echo "Error: Deploy key not found at $SSH_KEY_PATH" >&2
  exit 1
fi

# Ensure correct permissions on the private key
chmod 600 "$SSH_KEY_PATH"

# Force Git to use the specific deploy key and accept the GitHub host key
export GIT_SSH_COMMAND="ssh -i $SSH_KEY_PATH -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

# ==========================================
# Git Clone Operation
# ==========================================
if [[ -d "$TARGET_DIR" ]]; then
  echo "Directory '$TARGET_DIR' already exists. Skipping clone."
  exit 1
fi

echo "Cloning $REPO_URL into '$TARGET_DIR' using deploy key..."
git clone "$REPO_URL" "$TARGET_DIR"

echo "Repository successfully cloned to $(pwd)/$TARGET_DIR"
