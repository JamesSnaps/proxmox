# 🔐 Install 1Password CLI (if not already installed)
echo "🔐 Installing 1Password CLI..."
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | \
  sudo tee /etc/apt/sources.list.d/1password.list
sudo apt update && sudo apt install -y 1password-cli

# 🧑‍💻 Sign in to 1Password
echo "👉 Signing in to 1Password (manual step if not cached)..."
eval $(op signin) || { echo "❌ 1Password sign-in failed"; exit 1; }

# 📄 Fetch .env file from 1Password item
echo "📄 Downloading .env file from 1Password..."
if ! op item get "docker .env" --field "file" > /home/$USER/docker/.env; then
    echo "❌ Failed to download .env file from 1Password"
    exit 1
fi
chmod 600 /home/$USER/docker/.env
chown $USER:$USER /home/$USER/docker/.env
echo "✅ .env file added to Docker folder"