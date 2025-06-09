#!/bin/bash
set -euo pipefail

# --- CHECK REQUIRED COMMANDS ---
for cmd in curl xz qm pvesh awk grep sort ip; do
  command -v $cmd >/dev/null 2>&1 || { echo "❌ $cmd is required but not installed."; exit 1; }
done

# --- CHECK INTERNET CONNECTIVITY ---
echo "Checking internet connectivity..."
curl -s --head https://github.com/ > /dev/null || { echo "❌ No internet connection. Exiting."; exit 1; }

# --- LOGGING ---
LOGFILE="hass-setup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

# --- OVERVIEW ---
echo "" 
echo "🏠 Home Assistant Proxmox VM Setup Script"
echo "----------------------------------------"
echo "This script will:"
echo "  1. Download the latest Home Assistant OS image."
echo "  2. Create a new VM on your Proxmox server."
echo "  3. Import and configure the disk image."
echo "  4. Allow you to customize bridge, memory, cores, disk size, and VM name."
echo "  5. Clean up temporary files."
echo "  6. Log all actions to $LOGFILE."
echo ""
echo "⚠️  Please ensure you have sufficient resources and permissions."
echo ""
read -p "Would you like to proceed? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "❌ Exiting script. No changes made."
    exit 1
fi

# --- CONFIGURATION ---
echo ""
while true; do
  read -p "Enter a custom VMID or press Enter to use the next available one: " VMID
  if [ -z "$VMID" ]; then
    VMID=$(pvesh get /cluster/nextid)
    echo "Using next available VMID: $VMID"
    break
  else
    if qm status "$VMID" &>/dev/null; then
      echo "❌ VMID $VMID already exists. Please choose another."
    else
      echo "Using custom VMID: $VMID"
      break
    fi
  fi
done

read -p "Enter VM name [home-assistant]: " VMNAME
VMNAME=${VMNAME:-home-assistant}
STORAGE="local-zfs"

# Function to get available bridges
get_available_bridges() {
    for iface in /sys/class/net/vmbr*; do
        [ -d "$iface/bridge" ] && basename "$iface"
    done
}

# Get available bridges
echo "🔍 Available bridges:"
mapfile -t BRIDGES < <(get_available_bridges)
echo "Please select a bridge:"
for i in "${!BRIDGES[@]}"; do
    echo "$((i+1))) ${BRIDGES[$i]}"
done
while true; do
    read -p "Enter bridge number [1]: " BRIDGE_NUM
    BRIDGE_NUM=${BRIDGE_NUM:-1}
    if [[ "$BRIDGE_NUM" =~ ^[0-9]+$ ]] && [ "$BRIDGE_NUM" -ge 1 ] && [ "$BRIDGE_NUM" -le "${#BRIDGES[@]}" ]; then
        BRIDGE="${BRIDGES[$((BRIDGE_NUM-1))]}"
        break
    else
        echo "❌ Invalid selection. Please choose a number between 1 and ${#BRIDGES[@]}"
    fi
done

# Memory options
MEMORY_OPTIONS=(2048 4096 8192 16384 "Custom")
echo "Select memory size (MB):"
for i in "${!MEMORY_OPTIONS[@]}"; do
    echo "$((i+1))) ${MEMORY_OPTIONS[$i]}"
done
while true; do
    read -p "Enter memory option number [2]: " MEM_OPT
    MEM_OPT=${MEM_OPT:-2}
    if [[ "$MEM_OPT" =~ ^[0-9]+$ ]] && [ "$MEM_OPT" -ge 1 ] && [ "$MEM_OPT" -le "${#MEMORY_OPTIONS[@]}" ]; then
        if [ "${MEMORY_OPTIONS[$((MEM_OPT-1))]}" = "Custom" ]; then
            while true; do
                read -p "Enter custom memory size in MB: " MEMORY
                if [[ "$MEMORY" =~ ^[0-9]+$ ]] && [ "$MEMORY" -gt 0 ]; then
                    break
                else
                    echo "❌ Please enter a positive integer."
                fi
            done
        else
            MEMORY="${MEMORY_OPTIONS[$((MEM_OPT-1))]}"
        fi
        break
    else
        echo "❌ Invalid selection. Please choose a number between 1 and ${#MEMORY_OPTIONS[@]}"
    fi
done

read -p "Enter number of CPU cores [4]: " CORES
CORES=${CORES:-4}

# Disk size options
DISK_OPTIONS=(32 64 128 256 512 "Custom")
echo "Select disk size (GB):"
for i in "${!DISK_OPTIONS[@]}"; do
    echo "$((i+1))) ${DISK_OPTIONS[$i]}"
done
while true; do
    read -p "Enter disk size option number [4]: " DISK_OPT
    DISK_OPT=${DISK_OPT:-4}
    if [[ "$DISK_OPT" =~ ^[0-9]+$ ]] && [ "$DISK_OPT" -ge 1 ] && [ "$DISK_OPT" -le "${#DISK_OPTIONS[@]}" ]; then
        if [ "${DISK_OPTIONS[$((DISK_OPT-1))]}" = "Custom" ]; then
            while true; do
                read -p "Enter custom disk size in GB: " DISK_SIZE
                if [[ "$DISK_SIZE" =~ ^[0-9]+$ ]] && [ "$DISK_SIZE" -gt 0 ]; then
                    break
                else
                    echo "❌ Please enter a positive integer."
                fi
            done
        else
            DISK_SIZE="${DISK_OPTIONS[$((DISK_OPT-1))]}"
        fi
        break
    else
        echo "❌ Invalid selection. Please choose a number between 1 and ${#DISK_OPTIONS[@]}"
    fi
done

DISK_BUS="scsi0"

echo ""
echo "========= SUMMARY ========="
echo "VMID:        $VMID"
echo "VM Name:     $VMNAME"
echo "Bridge:      $BRIDGE"
echo "Memory:      ${MEMORY}MB"
echo "Cores:       $CORES"
echo "Disk Size:   ${DISK_SIZE}GB"
echo "Storage:     $STORAGE"
echo "==========================="
echo ""
read -p "Proceed with these settings? (y/n): " FINAL_CONFIRM
if [[ ! "$FINAL_CONFIRM" =~ ^[Yy]$ ]]; then
    echo "❌ Exiting script. No changes made."
    exit 1
fi

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

echo "🪛 Resizing disk to ${DISK_SIZE}GB..."
qm disk resize $VMID $DISK_BUS ${DISK_SIZE}G

echo "🔧 Configuring VM boot and disk..."
qm set $VMID --boot c --bootdisk $DISK_BUS
qm set $VMID --agent enabled=1

echo "✅ VM $VMID setup complete! Start it with: qm start $VMID"

# --- STEP 4: Cleanup ---
echo "🧹 Cleaning up temporary files..."
rm -f "$QCOW" "$QCOWXZ"
echo "🧽 Cleanup complete!"