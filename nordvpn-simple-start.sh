#!/bin/bash

set -e

echo "🔐 Starting encrypted VPN container..."

# Check required environment variables
if [[ -z "$NORDVPN_TOKEN" ]]; then
    echo "ERROR: NORDVPN_TOKEN environment variable is required"
    exit 1
fi

# Start nginx for web UI reverse proxy (runs in background)
echo "🔒 Starting web UI reverse proxy..."
if [ -f /etc/ssl/certs/stunnel.pem ]; then
    nginx &
    echo "✅ nginx reverse proxy active on ports 3443 (Firefox) and 8443 (qBittorrent web UI)"
    echo "🔧 nginx will properly handle Host headers for qBittorrent login"
    
    # Start stunnel for P2P traffic obfuscation (runs in background)
    echo "🔐 Starting P2P traffic obfuscation..."
    stunnel /etc/stunnel/stunnel-p2p.conf
    echo "✅ stunnel P2P obfuscation active on ports 6882, 6883 (encrypted BitTorrent)"
    echo "🛡️ BitTorrent protocol traffic will be encrypted and obfuscated"
else
    echo "⚠️  No TLS certificate found - continuing without encryption"
fi

# Start NordVPN daemon
echo "🌐 Starting NordVPN daemon..."
/usr/sbin/nordvpnd > /var/log/nordvpn.log 2>&1 &

# Give it time to start
echo "⏳ Waiting for daemon to start..."
sleep 10

# Connect to VPN
echo "🔑 Logging in and connecting to NordVPN..."
echo "n" | nordvpn login --token "$NORDVPN_TOKEN"
nordvpn set killswitch on
nordvpn connect "${NORDVPN_COUNTRY:-United_States}"

# Show access information
echo "✅ Secure VPN container startup complete"
echo "🔒 Encrypted access (ONLY - for security):"
echo "   - Firefox:     https://localhost:3443"
echo "   - qBittorrent: https://localhost:8443"
echo "⚠️  HTTP endpoints disabled to prevent host-level sniffing"
echo
echo "📋 Tailing NordVPN logs..."
tail -f /var/log/nordvpn.log