# 🔐 Install 1Password CLI (if not already installed)
echo "🔐 Installing 1Password CLI..."
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | \
  sudo tee /etc/apt/sources.list.d/1password.list
sudo apt update && sudo apt install -y 1password-cli

# 🧑‍💻 Sign in to 1Password
echo "👉 Signing in to 1Password (manual step if not cached)..."
eval $(op signin) || { echo "❌ 1Password sign-in failed"; exit 1; }

# 🤔 Ask which environment to use
echo "Which environment would you like to set up?"
echo "1) vm-core"
echo "2) vm-media"
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        env_name="vm-core .env"
        ;;
    2)
        env_name="vm-media .env"
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again and select 1 or 2."
        exit 1
        ;;
esac

# 📄 Fetch .env file from 1Password item
echo "📄 Downloading .env file from 1Password..."
op item get "$env_name" --field "file" > /home/$USER/docker/.env
chmod 600 /home/$USER/docker/.env
chown $USER:$USER /home/$USER/docker/.env
echo "✅ .env file added to Docker folder"