#!/bin/bash

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