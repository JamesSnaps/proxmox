#!/bin/bash

# -----------------------------------------------------------------------------
# Script: setup-synology-mounts.sh
# Purpose: Configure and mount Synology SMB shares on a new virtual machine
# 
# 🧰 What this script does:
# 1. Installs required packages (cifs-utils)
# 2. Creates mount directories under /mnt
# 3. Creates /etc/smb-cred-synology for credentials
# 4. Appends CIFS mount entries to /etc/fstab (if not already present)
# 5. Reloads systemd and mounts everything
#
# ✅ Usage:
#   sudo chmod +x setup-synology-mounts.sh
#   sudo ./setup-synology-mounts.sh
#
# 👇 Shares mounted:
#   //10.0.10.199/Movies4K     → /mnt/synology_media4k
#   //10.0.10.199/Media        → /mnt/synology_media
#   //10.0.10.199/Paperless    → /mnt/synology_paperless
#   //10.0.10.199/Sort         → /mnt/synology_sort
#   //10.0.10.199/SVRP         → /mnt/synology_svrp
#   //10.0.10.199/Syslogs      → /mnt/synology_syslogs
# -----------------------------------------------------------------------------

set -e

echo "⚠️  This script will:"
echo "- Install cifs-utils if it's not already installed"
echo "- Create mount folders under /mnt"
echo "- Create /etc/smb-cred-synology with credentials"
echo "- Update /etc/fstab with Synology SMB share mounts"
echo "- Reload systemd and mount all shares"

read -p "❓ Do you want to continue? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "❌ Aborted."
    exit 1
fi

# Define your SMB credentials
SMB_USERNAME="username"
SMB_PASSWORD="password"
SMB_SERVER="10.0.10.199"

# List of shares to mount
declare -A SHARES=(
  [Movies4K]=/mnt/synology_media4k
  [Media]=/mnt/synology_media
  [Paperless]=/mnt/synology_paperless
  [Sort]=/mnt/synology_sort
  [SVRP]=/mnt/synology_svrp
  [Syslogs]=/mnt/synology_syslogs
)

echo "🔧 Installing cifs-utils..."
apt update -y
apt install -y cifs-utils

echo "📁 Creating mount directories..."
for MOUNT_POINT in "${SHARES[@]}"; do
  mkdir -p "$MOUNT_POINT"
done

echo "🔐 Creating credentials file..."
CRED_FILE="/etc/smb-cred-synology"
echo "username=${SMB_USERNAME}" > "$CRED_FILE"
echo "password=${SMB_PASSWORD}" >> "$CRED_FILE"
chmod 600 "$CRED_FILE"
chown root:root "$CRED_FILE"

echo "📝 Adding entries to /etc/fstab..."
for SHARE_NAME in "${!SHARES[@]}"; do
  MOUNT_PATH="${SHARES[$SHARE_NAME]}"
  FSTAB_ENTRY="//${SMB_SERVER}/${SHARE_NAME} ${MOUNT_PATH} cifs credentials=${CRED_FILE},vers=3.0,rw,uid=1000,gid=1000,file_mode=0664,dir_mode=0775,nofail,x-systemd.automount,_netdev 0 0"

  grep -qF "$MOUNT_PATH" /etc/fstab || echo "$FSTAB_ENTRY" >> /etc/fstab
done

echo "🔁 Reloading systemd and mounting all filesystems..."
systemctl daemon-reexec
systemctl daemon-reload
mount -a

echo "✅ All Synology shares mounted successfully."