#!/bin/bash

# Start (or restart) the VPN stack
# This script starts all containers: NordVPN, Firefox, and qBittorrent

set -e

echo "🚀 Starting VPN stack..."
echo

# Source environment variables
if [ -f .env ]; then
    echo "📄 Loading environment variables from .env..."
    source .env
else
    echo "⚠️  Warning: .env file not found. Make sure NORDVPN_TOKEN is set."
fi

# Build custom NordVPN container if needed
echo "🔨 Building custom NordVPN container..."
podman build -t localhost/test-nordvpn:latest -f Dockerfile.nordvpn .

# Start the stack
echo "🐳 Starting containers..."
podman-compose -f compose-vpn.yml up -d

echo
echo "⏳ Waiting for services to start..."
sleep 15

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
    fi
else
    echo "🔄 VPN: Starting..."
fi

echo
echo "✨ Stack startup complete!"
echo
echo "📊 Run './check-vpn-status.sh' for detailed health check"
echo "🛑 Run './stop-everything.sh' to shut down everything"