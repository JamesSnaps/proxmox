# Sets up a new LXC container for ssh access
#!/bin/bash

# Interactive SSH setup for LXC
read -p "Enter LXC Container ID: " CTID
read -p "Enter username to enable SSH for: " USERNAME

read -p "Create user '$USERNAME' if it doesn't exist? (y/n): " CREATEUSER
if [[ "$CREATEUSER" == "y" ]]; then
  pct exec "$CTID" -- bash -c "id -u $USERNAME &>/dev/null || (adduser --disabled-password --gecos \"\" $USERNAME && usermod -aG sudo $USERNAME)"
fi

echo "Installing OpenSSH in container $CTID..."

pct exec "$CTID" -- apt update
pct exec "$CTID" -- apt install -y openssh-server

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