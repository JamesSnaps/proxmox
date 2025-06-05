# Sets up a new LXC container for ssh access
#!/bin/bash

# Interactive SSH setup for LXC
read -p "Enter LXC Container ID: " CTID
read -p "Enter username to enable SSH for: " USERNAME

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

echo "Getting IP address of container $CTID..."
CTIP=$(pct exec "$CTID" -- hostname -I | awk '{print $1}')
echo "Container IP: $CTIP"

echo "You can now SSH into the container:"
echo "ssh $USERNAME@$CTIP"