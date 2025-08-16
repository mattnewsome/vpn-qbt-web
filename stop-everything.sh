#!/bin/bash

# Stop the VPN stack
# This script stops all containers: NordVPN, Firefox, and qBittorrent

set -e

echo "🛑 Stopping VPN stack..."
echo

# Stop all containers
echo "🐳 Stopping containers..."
podman-compose -f compose-vpn.yml down

echo
echo "🔍 Verifying shutdown..."

# Check if containers are still running
RUNNING_CONTAINERS=$(podman ps --filter name="nordvpn\|firefox\|qbittorrent" --format "{{.Names}}" | wc -l)

if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
    echo "✅ All containers stopped successfully"
else
    echo "⚠️  Some containers may still be running:"
    podman ps --filter name="nordvpn\|firefox\|qbittorrent" --format "table {{.Names}}\t{{.Status}}"
fi

echo
echo "🔌 Services are no longer accessible:"
echo "   Firefox:     http://localhost:3000"
echo "   qBittorrent: http://localhost:8080"

echo
echo "✨ Shutdown complete!"
echo
echo "🚀 Run './start-everything.sh' to start everything again"