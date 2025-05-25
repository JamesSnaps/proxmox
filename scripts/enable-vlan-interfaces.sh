#!/bin/bash

set -e

# Define the Netplan config file
NETPLAN_FILE="/etc/netplan/99-vlans.yaml"

# Interfaces to bring up
INTERFACES=("ens19" "ens20" "ens21")

echo "🔧 Creating Netplan config for VLAN interfaces..."

# Build Netplan YAML
cat <<EOF > "$NETPLAN_FILE"
network:
  version: 2
  ethernets:
EOF

for iface in "${INTERFACES[@]}"; do
  echo "    $iface:" >> "$NETPLAN_FILE"
  echo "      dhcp4: no" >> "$NETPLAN_FILE"
done

echo "✅ Applying Netplan config..."
netplan apply

# Also bring interfaces up now just in case
for iface in "${INTERFACES[@]}"; do
  echo "🔌 Bringing up $iface manually..."
  ip link set "$iface" up || true
done

echo "✅ VLAN interfaces configured and active."