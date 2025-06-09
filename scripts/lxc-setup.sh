# Sets up a new LXC container for ssh access
#!/bin/bash

echo "📝 This script is designed to be run on the Proxmox host (not inside the LXC container) and will:"
echo "  1. Create a new user (optional)"
echo "  2. Configure sudo access for the user"
echo "  3. Set up locale and install OpenSSH"
echo "  4. Enable and start the SSH service"
echo "  5. Set up password authentication (optional)"
echo "  6. Configure SSH key-based authentication (optional)"
echo "  7. Disable root SSH login (optional)"
echo ""
echo "⚠️  Note: This script requires Proxmox VE (pct) command access and sudo privileges."
echo ""

# Ask for confirmation
read -p "Would you like to proceed? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operation cancelled by user."
    exit 1
fi

# Interactive SSH setup for LXC
read -p "Enter LXC Container ID: " CTID
read -p "Enter username to enable SSH for: " USERNAME

read -p "Create user '$USERNAME' if it doesn't exist? (y/n): " CREATEUSER
if [[ "$CREATEUSER" == "y" ]]; then
  # Create user with a temporary password that will be changed later if needed
  pct exec "$CTID" -- bash -c "id -u $USERNAME &>/dev/null || (adduser --gecos \"\" $USERNAME && usermod -aG sudo $USERNAME)"
  # Configure sudo to work without password for this user
  pct exec "$CTID" -- bash -c "echo '$USERNAME ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$USERNAME"
  pct exec "$CTID" -- chmod 440 /etc/sudoers.d/$USERNAME
  # Verify sudo access
  pct exec "$CTID" -- bash -c "su - $USERNAME -c 'sudo -n true'"
  if [ $? -eq 0 ]; then
    echo "Sudo access configured successfully for $USERNAME"
  else
    echo "Warning: Sudo access configuration may have failed for $USERNAME"
  fi
fi

echo "Setting up locale..."
pct exec "$CTID" -- locale-gen en_US.UTF-8
pct exec "$CTID" -- update-locale LANG=en_US.UTF-8

echo "Installing OpenSSH in container $CTID..."

pct exec "$CTID" -- apt update
pct exec "$CTID" -- apt install -y openssh-server locales

echo "Enabling SSH service..."
pct exec "$CTID" -- systemctl enable ssh
pct exec "$CTID" -- systemctl start ssh


read -p "Do you want to set a password for $USERNAME? (y/n): " SETPASS
if [[ "$SETPASS" == "y" ]]; then
  pct exec "$CTID" -- passwd "$USERNAME"
fi

# Optionally copy SSH public key for passwordless login
read -p "Do you want to copy your SSH public key to the container for passwordless login? (y/n): " COPYKEY
if [[ "$COPYKEY" == "y" ]]; then
  read -p "Do you want to input your public key directly? (y/n): " DIRECT_KEY
  if [[ "$DIRECT_KEY" == "y" ]]; then
    echo "Please paste your public key (press Enter, then Ctrl+D when done):"
    PUBKEY=$(cat)
  else
    read -p "Enter path to your public SSH key (default: ~/.ssh/id_rsa.pub): " KEY_PATH
    KEY_PATH=${KEY_PATH:-~/.ssh/id_rsa.pub}
    if [[ -f "$KEY_PATH" ]]; then
      PUBKEY=$(cat "$KEY_PATH")
    else
      echo "SSH key file not found at $KEY_PATH. Skipping key copy."
      continue
    fi
  fi
  
  pct exec "$CTID" -- mkdir -p /home/"$USERNAME"/.ssh
  pct exec "$CTID" -- bash -c "echo '$PUBKEY' >> /home/$USERNAME/.ssh/authorized_keys"
  pct exec "$CTID" -- chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh
  pct exec "$CTID" -- chmod 700 /home/"$USERNAME"/.ssh
  pct exec "$CTID" -- chmod 600 /home/"$USERNAME"/.ssh/authorized_keys

  read -p "Disable root SSH login for security? (y/n): " DISABLEROOT
  if [[ "$DISABLEROOT" == "y" ]]; then
    pct exec "$CTID" -- sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    pct exec "$CTID" -- systemctl restart ssh
    echo "Root SSH login disabled."
  fi
fi

echo "Getting IP address of container $CTID..."
CTIP=$(pct exec "$CTID" -- hostname -I | awk '{print $1}')
echo "Container IP: $CTIP"

echo "You can now SSH into the container:"
echo "ssh $USERNAME@$CTIP"