#!/bin/bash

# Allow passwordless sudo for the current user
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER

# Update and install required packages
echo "🔧 Updating system and installing prerequisites..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    openssh-server \
    ntp \

# Set up Docker’s official GPG key
echo "📦 Adding Docker repository..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo "🐳 Installing Docker Engine..."
sudo apt update
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Install and configure automatic security updates
echo "🔒 Setting up automatic security updates..."
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Start and enable Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to Docker group
echo "👤 Adding $USER to docker group..."
sudo usermod -aG docker $USER

# Install and enable QEMU Guest Agent
echo "📡 Installing QEMU Guest Agent..."
sudo apt install -y qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent

# Set Docker to use shared appdata folder (via VirtioFS)
echo "📁 Configuring Docker to use shared VirtioFS storage..."

# Create the Docker data-root directory inside the VM
sudo mkdir -p /mnt/docker-data/docker

# Configure Docker to use it
echo '{ "data-root": "/mnt/docker-data/docker" }' | sudo tee /etc/docker/daemon.json

# Restart Docker to apply changes
sudo systemctl restart docker

echo "✅ Docker is now configured to use /mnt/docker-data/docker (backed by host's VirtioFS)"


# Install Netdata monitoring
echo "📊 Installing Netdata for monitoring..."
bash <(curl -L -Ss https://my-netdata.io/kickstart.sh)
vm_ip=$(hostname -I | awk '{print $1}')
echo "✅ Netdata installation complete. Access it via http://$vm_ip:19999"

# 🔑 Prompt user for SSH public key and configure passwordless login
echo "🔑 Enter your SSH public key (starting with 'ssh-rsa', 'ssh-ed25519', etc.):"
read -r ssh_pub_key

if [[ "$ssh_pub_key" == ssh-* ]]; then
    echo "🔐 Setting up SSH key for $USER..."
    mkdir -p /home/$USER/.ssh
    echo "$ssh_pub_key" > /home/$USER/.ssh/authorized_keys
    chmod 600 /home/$USER/.ssh/authorized_keys
    chown -R $USER:$USER /home/$USER/.ssh
    echo "✅ SSH key added for $USER"
else
    echo "⚠️ Invalid SSH key format. Skipping SSH key setup."
fi

echo "✅ Bootstrap complete! You may need to log out and back in to use Docker without sudo."