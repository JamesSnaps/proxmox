#!/bin/bash

set -e

# Interfaces to enable
INTERFACES=("ens19" "ens20" "ens21")

echo "🔧 Backing up /etc/network/interfaces to /etc/network/interfaces.bak..."
cp /etc/network/interfaces /etc/network/interfaces.bak

for iface in "${INTERFACES[@]}"; do
    # Check if the interface config already exists
    if ! grep -q "auto $iface" /etc/network/interfaces; then
        echo "✅ Adding $iface to /etc/network/interfaces..."
        echo -e "\nauto $iface\niface $iface inet manual" >> /etc/network/interfaces
    else
        echo "ℹ️ Interface $iface already configured in /etc/network/interfaces"
    fi

    # Bring the interface up immediately
    echo "🔌 Bringing up $iface..."
    ip link set "$iface" up
done

echo "✅ All interfaces configured and brought up."