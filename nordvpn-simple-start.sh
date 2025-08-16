#!/bin/bash

set -e

echo "Starting NordVPN container..."

# Check required environment variables
if [[ -z "$NORDVPN_TOKEN" ]]; then
    echo "ERROR: NORDVPN_TOKEN environment variable is required"
    exit 1
fi

# Simple approach - just start daemon and connect
echo "Starting daemon..."
/usr/sbin/nordvpnd > /var/log/nordvpn.log 2>&1 &

# Give it time to start
sleep 10

# Simple connection attempt
echo "Attempting connection..."
echo "n" | nordvpn login --token "$NORDVPN_TOKEN"
nordvpn set killswitch off
nordvpn connect United_States

# Keep running
echo "VPN setup complete, keeping container alive..."
tail -f /var/log/nordvpn.log