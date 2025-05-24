#!/bin/bash

# --- CONFIGURATION ---
VMID=${1:-$(pvesh get /cluster/nextid)}
VMNAME="home-assistant"
STORAGE="local-zfs"
BRIDGE="vmbr2021"
MEMORY="4096"
CORES="4"
DISK_BUS="scsi0"

echo "🧩 Using VMID: $VMID"

# --- STEP 1: Fetch latest release URL ---
echo "🔍 Fetching latest Home Assistant OS release..."
BASE_URL="https://github.com/home-assistant/operating-system/releases/latest/download"
FILENAME=$(curl -sL -o /dev/null -w %{url_effective} https://github.com/home-assistant/operating-system/releases/latest | grep -oP 'tag/\K[^/]+')
QCOWXZ="haos_ova-$FILENAME.qcow2.xz"
FULL_URL="$BASE_URL/$QCOWXZ"

echo "📥 Downloading $QCOWXZ..."
curl -L -o "$QCOWXZ" "$FULL_URL" || { echo "❌ Download failed"; exit 1; }

# --- STEP 2: Decompress ---
echo "📦 Decompressing..."
xz -dk "$QCOWXZ" || { echo "❌ Failed to decompress file"; exit 1; }
QCOW="${QCOWXZ%.xz}"

# --- STEP 3: Create and Import VM ---
echo "🖥 Creating VM ID $VMID..."
qm create $VMID --name $VMNAME --memory $MEMORY --cores $CORES \
  --net0 virtio,bridge=$BRIDGE --ostype l26 --bios ovmf --machine q35

echo "📂 Importing disk..."
qm importdisk $VMID "$QCOW" $STORAGE || { echo "❌ Disk import failed"; exit 1; }

echo "🔧 Attaching disk to VM..."
qm set $VMID --scsihw virtio-scsi-pci --$DISK_BUS $STORAGE:vm-${VMID}-disk-0

echo "🪛 Resizing disk to 256GB..."
qm disk resize $VMID $DISK_BUS 256G

echo "🔧 Configuring VM boot and disk..."
qm set $VMID --boot c --bootdisk $DISK_BUS
qm set $VMID --agent enabled=1

echo "✅ VM $VMID setup complete! Start it with: qm start $VMID"

# --- STEP 4: Cleanup ---
echo "🧹 Cleaning up temporary files..."
rm -f "$QCOW" "$QCOWXZ"
echo "🧽 Cleanup complete!"