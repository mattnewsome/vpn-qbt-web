#!/bin/bash

# Restart the VPN stack
# This script stops everything cleanly, then starts it all back up

set -e

echo "🔄 Restarting VPN stack..."
echo

# Stop everything first
echo "🛑 Step 1: Stopping all containers..."
podman-compose -f compose-vpn.yml down

echo "⏳ Waiting for clean shutdown..."
sleep 5

# Verify everything is stopped
RUNNING_CONTAINERS=$(podman ps --filter name="nordvpn\|firefox\|qbittorrent" --format "{{.Names}}" | wc -l)
if [ "$RUNNING_CONTAINERS" -gt 0 ]; then
    echo "⚠️  Force stopping remaining containers..."
    podman ps --filter name="nordvpn\|firefox\|qbittorrent" --format "{{.Names}}" | xargs -r podman stop
fi

echo "✅ All containers stopped"
echo

# Source environment variables
echo "🚀 Step 2: Starting everything back up..."
if [ -f .env ]; then
    echo "📄 Loading environment variables from .env..."
    source .env
else
    echo "⚠️  Warning: .env file not found. Make sure NORDVPN_TOKEN is set."
fi

# Start the stack
echo "🐳 Starting containers..."
podman-compose -f compose-vpn.yml up -d

echo
echo "⏳ Waiting for services to start..."
sleep 20

# Check if services are accessible
echo "🔍 Checking service health..."

FIREFOX_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 || echo "000")
QB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 || echo "000")

if [ "$FIREFOX_STATUS" = "200" ]; then
    echo "✅ Firefox:     http://localhost:3000 (Ready)"
else
    echo "🔄 Firefox:     http://localhost:3000 (Starting...)"
fi

if [ "$QB_STATUS" = "200" ]; then
    echo "✅ qBittorrent: http://localhost:8080 (Ready)"
else
    echo "🔄 qBittorrent: http://localhost:8080 (Starting...)"
fi

echo
echo "🔗 VPN Status:"
if podman exec nordvpn nordvpn status >/dev/null 2>&1; then
    VPN_STATUS=$(podman exec nordvpn nordvpn status | grep "Status:" | cut -d' ' -f2)
    if [ "$VPN_STATUS" = "Connected" ]; then
        VPN_IP=$(podman exec nordvpn curl -s ifconfig.me 2>/dev/null || echo "Unknown")
        VPN_SERVER=$(podman exec nordvpn nordvpn status | grep "Server:" | cut -d' ' -f2- || echo "Unknown")
        echo "✅ VPN Connected: $VPN_SERVER"
        echo "🌐 VPN IP: $VPN_IP"
    else
        echo "🔄 VPN Status: $VPN_STATUS"
        echo "💡 VPN may still be connecting..."
    fi
else
    echo "🔄 VPN: Starting..."
    echo "💡 VPN may take a minute to fully connect"
fi

echo
echo "🔄 Restart complete!"
echo
echo "💡 If services aren't ready yet, wait 30-60 seconds and check again"
echo "📊 Run './check-vpn-status.sh' for detailed health check"
echo "🛑 Run './stop-everything.sh' to shut down everything"