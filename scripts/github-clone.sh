#!/bin/bash

# 🔧 Set your repo and folder choices here
GITHUB_USER="JamesSnaps"
REPO_NAME="docker"  # e.g., private repo name

# Prompt user to select which folder to clone
echo "Which stack do you want to clone? (vm-core or vm-media)"
read -r STACK_FOLDER
if [[ "$STACK_FOLDER" != "vm-core" && "$STACK_FOLDER" != "vm-media" ]]; then
  echo "❌ Invalid option. Please choose either 'vm-core' or 'vm-media'."
  exit 1
fi

DEST_FOLDER="/home/$USER/docker/$STACK_FOLDER"

# 📦 Check if GitHub CLI is installed, install if missing
if ! command -v gh &> /dev/null; then
  echo "🔧 GitHub CLI not found. Installing..."

  # Detect OS and install GitHub CLI
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    type -p curl >/dev/null || sudo apt update && sudo apt install curl -y
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
      sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
      sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update && sudo apt install gh -y
  else
    echo "❌ Unsupported OS or please install GitHub CLI manually from https://cli.github.com"
    exit 1
  fi
fi

# 🔐 Authenticate if needed
echo "🔐 Checking GitHub authentication..."
gh auth status &> /dev/null || gh auth login

# 📁 Clone the repo
echo "📁 Cloning private repo '$REPO_NAME'..."
TMP_DIR=$(mktemp -d)
gh repo clone "$GITHUB_USER/$REPO_NAME" "$TMP_DIR"

# 📂 Copy the desired stack folder
echo "📂 Copying $STACK_FOLDER to $DEST_FOLDER..."
mkdir -p "$DEST_FOLDER"
cp -r "$TMP_DIR/docker-stacks/$STACK_FOLDER/"* "$DEST_FOLDER"

# 🧹 Cleanup
rm -rf "$TMP_DIR"
echo "✅ $STACK_FOLDER copied to $DEST_FOLDER"