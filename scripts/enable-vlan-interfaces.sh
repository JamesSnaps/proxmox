#!/bin/bash

# Don't exit on errors since we want to handle missing interfaces gracefully
# set -e

# Define the Netplan config file
NETPLAN_FILE="/etc/netplan/99-vlans.yaml"

# Interfaces to bring up
INTERFACES=("ens19" "ens20" "ens21" "ens22" "ens23")

echo "🔧 Creating Netplan config for VLAN interfaces..."

# Build Netplan YAML
cat <<EOF > "$NETPLAN_FILE"
network:
  version: 2
  ethernets:
EOF

# Track if we found any valid interfaces
found_interfaces=false

for iface in "${INTERFACES[@]}"; do
  # Check if interface exists
  if ip link show "$iface" >/dev/null 2>&1; then
    echo "    $iface:" >> "$NETPLAN_FILE"
    echo "      dhcp4: no" >> "$NETPLAN_FILE"
    found_interfaces=true
  else
    echo "⚠️  Interface $iface not found, skipping..."
  fi
done

if [ "$found_interfaces" = true ]; then
  echo "✅ Applying Netplan config..."
  netplan apply

  # Also bring interfaces up now just in case
  for iface in "${INTERFACES[@]}"; do
    if ip link show "$iface" >/dev/null 2>&1; then
      echo "🔌 Bringing up $iface manually..."
      ip link set "$iface" up || true
    fi
  done

  echo "✅ VLAN interfaces configured and active."
else
  echo "❌ No valid interfaces found to configure."
  exit 1
fi