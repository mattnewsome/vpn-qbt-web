#!/bin/bash

# Exit on any error
set -e

echo "Starting NordVPN container..."

# Check required environment variables
if [[ -z "$NORDVPN_TOKEN" ]]; then
    echo "ERROR: NORDVPN_TOKEN environment variable is required"
    echo "Generate an access token from your NordVPN dashboard"
    exit 1
fi

# Check if daemon is already running and kill if needed
if pgrep -f nordvpnd > /dev/null; then
    echo "Killing existing daemon..."
    pkill -f nordvpnd
    sleep 3
fi

# Start nordvpn daemon
echo "Starting NordVPN daemon..."
/usr/sbin/nordvpnd > /dev/null 2>&1 &
DAEMON_PID=$!
sleep 8

# Check if daemon started successfully
if ! kill -0 $DAEMON_PID 2>/dev/null; then
    echo "Daemon failed to start, exiting..."
    exit 1
fi

# Wait for daemon to be ready
echo "Waiting for daemon to be ready..."
for i in {1..15}; do
    if nordvpn status >/dev/null 2>&1; then
        echo "NordVPN daemon is ready"
        break
    fi
    echo "Waiting for daemon... ($i/15)"
    sleep 3
done

# Check if daemon is actually ready
if ! nordvpn status >/dev/null 2>&1; then
    echo "Daemon not responding, exiting..."
    exit 1
fi

# Login to NordVPN
echo "Logging into NordVPN..."
printf "n\n" | nordvpn login --token "$NORDVPN_TOKEN"

# Check login status
if ! nordvpn account >/dev/null 2>&1; then
    echo "Login failed, exiting..."
    exit 1
fi

# Set connection settings
echo "Configuring NordVPN settings..."
nordvpn set technology NordLynx
nordvpn set protocol udp
nordvpn set killswitch on
nordvpn set autoconnect on

# Allow local network access for container communication
if [[ -n "$LOCAL_NETWORK" ]]; then
    echo "Allowing local network: $LOCAL_NETWORK"
    IFS=',' read -ra NETWORKS <<< "$LOCAL_NETWORK"
    for network in "${NETWORKS[@]}"; do
        network=$(echo "$network" | xargs) # trim whitespace
        nordvpn whitelist add subnet "$network"
    done
fi

# Connect to VPN
CONNECT_TO="${NORDVPN_COUNTRY:-United_States}"
echo "Connecting to NordVPN server in: $CONNECT_TO"
nordvpn connect "$CONNECT_TO"

# Wait for connection to establish
sleep 15

# Verify connection
echo "Verifying VPN connection..."
if nordvpn status | grep -q "Status: Connected"; then
    echo "VPN connected successfully!"
    nordvpn status
else
    echo "VPN connection failed!"
    nordvpn status
    exit 1
fi

# Keep container running and monitor VPN connection
echo "Monitoring VPN connection..."
while true; do
    if ! nordvpn status | grep -q "Status: Connected"; then
        echo "VPN connection lost, attempting to reconnect..."
        nordvpn connect "$CONNECT_TO"
        sleep 15
    fi
    sleep 30
done