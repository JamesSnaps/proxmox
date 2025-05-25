#!/bin/bash

# 🔧 Set your repo and folder choices here
GITHUB_USER="JamesSnaps"
REPO_NAME="docker"  # e.g., private repo name

# Create a numbered selection menu
echo "Which stack do you want to clone?"
echo "1) vm-core"
echo "2) vm-media"
read -p "Enter your choice (1 or 2): " choice

# Convert choice to folder name
case $choice in
    1)
        STACK_FOLDER="vm-core"
        ;;
    2)
        STACK_FOLDER="vm-media"
        ;;
    *)
        echo "❌ Invalid option. Please choose either 1 or 2."
        exit 1
        ;;
esac

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