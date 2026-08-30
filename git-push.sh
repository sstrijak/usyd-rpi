#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# ==========================================
# Configuration
# ==========================================
SSH_KEY_PATH="$HOME/.ssh/usyd-rpi@github.com" # Path to your private SSH key
BRANCH_NAME="main"                            # Branch you want to push to
REMOTE_NAME="origin"                          # Git remote name
COMMIT_MSG="${1:-Auto-commit: $(date +'%Y-%m-%d %H:%M:%S')}" # Optional CLI argument

# ==========================================
# Validation & Setup
# ==========================================
if [[ ! -f "$SSH_KEY_PATH" ]]; then
  echo "Error: SSH key not found at $SSH_KEY_PATH" >&2
  exit 1
fi

# Ensure correct permissions on the private key
chmod 600 "$SSH_KEY_PATH"

# Force Git to use the specified SSH key without interactive host verification prompts
export GIT_SSH_COMMAND="ssh -i $SSH_KEY_PATH -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

# ==========================================
# Git Operations
# ==========================================
echo "Staging changes..."
git add -A

# Check if there are changes to commit
if git diff --cached --quiet; then
  echo "No changes to commit. Proceeding to push..."
else
  echo "Committing: '$COMMIT_MSG'"
  git commit -m "$COMMIT_MSG"
fi

echo "Pushing to $REMOTE_NAME/$BRANCH_NAME..."
git push "$REMOTE_NAME" "$BRANCH_NAME"

echo "Successfully pushed to GitHub!"



