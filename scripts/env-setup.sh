#!/bin/bash

echo "📝 This script will:"
echo "  1. Install the 1Password CLI tool"
echo "  2. Sign you into 1Password (if not already signed in)"
echo "  3. Download your Docker .env file from 1Password"
echo "  4. Set appropriate permissions on the .env file"
echo ""
echo "⚠️  Note: This script requires sudo privileges for installation steps."
echo ""

# Ask for confirmation
# When script is piped (curl | bash), stdin contains the script, so read from /dev/tty
# When run directly, stdin is the terminal, so read normally
if [ -t 0 ]; then
    # stdin is a terminal, read directly
    read -p "Would you like to proceed? (y/N) " -n 1 -r
else
    # stdin is piped (script content), read from /dev/tty
    # In a real terminal (curl | bash), /dev/tty will be available
    read -p "Would you like to proceed? (y/N) " -n 1 -r < /dev/tty 2>/dev/null || {
        echo ""
        echo "❌ Cannot read from terminal. Please run this script in an interactive terminal."
        exit 1
    }
fi
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operation cancelled by user."
    exit 1
fi

# 🔐 Install 1Password CLI (if not already installed)
echo "🔐 Installing 1Password CLI..."
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | \
  sudo tee /etc/apt/sources.list.d/1password.list
sudo apt update && sudo apt install -y 1password-cli

# 🧑‍💻 Sign in to 1Password
# Check if already signed in
if ! op account list | grep -q 'SIGNED_IN'; then
    echo "👉 Signing in to 1Password (manual step)..."
    eval $(op signin) || { echo "❌ 1Password sign-in failed"; exit 1; }
fi

echo "📄 Downloading .env file from 1Password..."
# The .env lives only in 1Password (see docs/auto-deploy.md in the docker
# repo). After this first copy, docker/scripts/env-refresh.sh keeps it current
# using a read-only service account.
if ! op document get "${OP_ENV_DOCUMENT:-docker .env}" --vault "${OP_ENV_VAULT:-Homelab}" > /home/$USER/docker/.env; then
    echo "❌ Failed to download .env file from 1Password"
    exit 1
fi
chmod 600 /home/$USER/docker/.env
chown $USER:$USER /home/$USER/docker/.env
echo "✅ .env file added to Docker folder"