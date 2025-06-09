#!/bin/bash

echo "📝 This script is designed to be run inside a VM and will set up various mount points by:"
echo "  1. Creating mount points for Synology NFS shares:"
echo "     - /mnt/synology_media4k"
echo "     - /mnt/synology_media"
echo "     - /mnt/synology_paperless"
echo "     - /mnt/synology_sort"
echo "     - /mnt/synology_svrp"
echo "     - /mnt/synology_syslogs"
echo "  2. Backing up /etc/fstab to /etc/fstab.bak"
echo "  3. Adding NFS mount configurations to /etc/fstab"
echo "  4. Creating mount points for virtiofs shares:"
echo "     - /mnt/docker-core"
echo "     - /mnt/plex-data"
echo "     - /mnt/docker-media"
echo "     - /mnt/plex-transcodes"
echo "     - /mnt/downloads"
echo "  5. Mounting all configured shares"
echo ""
echo "⚠️  Note: This script requires sudo privileges and assumes the Synology NAS is accessible at 10.0.10.199"
echo ""

# Ask for confirmation
read -p "Would you like to proceed? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operation cancelled by user."
    exit 1
fi

echo "📁 Creating mount points..."
sudo mkdir -p /mnt/synology_media4k
sudo mkdir -p /mnt/synology_media
sudo mkdir -p /mnt/synology_paperless
sudo mkdir -p /mnt/synology_sort
sudo mkdir -p /mnt/synology_svrp
sudo mkdir -p /mnt/synology_syslogs


echo "📝 Backing up /etc/fstab to /etc/fstab.bak..."
sudo cp /etc/fstab /etc/fstab.bak

echo "🔗 Adding NFS mounts to /etc/fstab..."
cat <<EOF | sudo tee -a /etc/fstab

# Synology Media Mounts
10.0.10.199:/volume2/Movies4K   /mnt/synology_media4k nfs defaults,_netdev 0 0
10.0.10.199:/volume1/Media       /mnt/synology_media     nfs defaults,_netdev 0 0
10.0.10.199:/volume1/Paperless    /mnt/synology_paperless  nfs defaults,_netdev 0 0
10.0.10.199:/volume1/Sort     /mnt/synology_sort     nfs defaults,_netdev 0 0
10.0.10.199:/volume1/SVRP     /mnt/synology_svrp     nfs defaults,_netdev 0 0
10.0.10.199:/volume1/Syslogs  /mnt/synology_syslogs  nfs defaults,_netdev 0 0
EOF

echo "🔄 Mounting all file systems..."
sudo mount -a

echo "✅ Media shares mounted!"

echo "📁 Creating virtiofs mount points for docker-data..."
sudo mkdir -p /mnt/docker-core
sudo mkdir -p /mnt/plex-data
sudo mkdir -p /mnt/docker-media
sudo mkdir -p /mnt/plex-transcodes
sudo mkdir -p /mnt/downloads

echo "🔗 Mounting virtiofs shares..."
sudo mount -t virtiofs appdata-core /mnt/docker-core
sudo mount -t virtiofs plex /mnt/plex-data
sudo mount -t virtiofs appdata_media /mnt/docker-media
sudo mount -t virtiofs plex-transcodes /mnt/plex-transcodes
sudo mount -t virtiofs downloads /mnt/downloads

echo "✅ Virtiofs shares mounted!"