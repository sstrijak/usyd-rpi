#!/usr/bin/env bash

set -e

# ==========================================
# Configuration
# ==========================================
SSH_KEY_PATH="$HOME/.ssh/usyd-rpi.ro@github.com" # Path to your private deploy key
REMOTE_NAME="origin"                          # Default Git remote name
TARGET_DIR="${1:-.}"                          # Target repo path (defaults to current dir)

# ==========================================
# Directory & Validation Setup
# ==========================================
if [[ ! -d "$TARGET_DIR/.git" ]]; then
  echo "Error: '$TARGET_DIR' is not a valid Git repository." >&2
  exit 1
fi

cd "$TARGET_DIR"

if [[ ! -f "$SSH_KEY_PATH" ]]; then
  echo "Error: Deploy key not found at $SSH_KEY_PATH" >&2
  exit 1
fi

# Ensure strict file permissions for SSH key
chmod 600 "$SSH_KEY_PATH"

# Force Git to use the specific deploy key
export GIT_SSH_COMMAND="ssh -i $SSH_KEY_PATH -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

# Automatically resolve the current checked-out branch name
BRANCH_NAME="$(git symbolic-ref --short HEAD)"

# ==========================================
# Git Pull Operation
# ==========================================
echo "Pulling latest changes for branch '$BRANCH_NAME' from '$REMOTE_NAME'..."
git pull "$REMOTE_NAME" "$BRANCH_NAME"

echo "Repository is up to date."
