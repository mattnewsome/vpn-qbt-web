#!/bin/bash

# Start (or restart) the VPN stack
# This script starts all containers: NordVPN, Firefox, and qBittorrent

set -e

echo "🚀 Starting VPN stack..."
echo

# Check Red Hat registry access by attempting fresh pull
echo "🔍 Checking Red Hat registry access..."
echo "🔐 Testing registry authentication (this ensures you have access)..."
if ! podman pull registry.redhat.io/rhel9/toolbox:latest --quiet 2>/dev/null; then
    echo "❌ Cannot access Red Hat registry. You need to login first."
    echo "📋 Steps to get access:"
    echo "   1. Create free account at: https://developers.redhat.com/"
    echo "   2. Login below with your Red Hat credentials"
    echo ""
    echo "🔐 Logging into Red Hat registry..."
    if ! podman login registry.redhat.io; then
        echo "❌ Red Hat registry login failed. Please check your credentials."
        exit 1
    fi
    echo "✅ Red Hat registry login successful!"
    echo "🔄 Retrying base image pull..."
    podman pull registry.redhat.io/rhel9/toolbox:latest --quiet
else
    echo "✅ Red Hat registry access confirmed"
fi
echo

# Source environment variables
if [ -f .env ]; then
    echo "📄 Loading environment variables from .env..."
    source .env
else
    echo "⚠️  Warning: .env file not found. Make sure NORDVPN_TOKEN is set."
fi

# Generate TLS certificates for encryption if they don't exist
if [ ! -f ./certs/stunnel.pem ]; then
    echo "🔐 Generating TLS certificates for encrypted communication..."
    ./generate-certs.sh
else
    echo "✅ TLS certificates already exist"
fi

# Build custom NordVPN container with encryption
echo "🔨 Building encrypted VPN container..."
podman build -t localhost/test-nordvpn:latest -f Dockerfile.nordvpn .

# Start the stack
echo "🐳 Starting containers..."
podman-compose -f compose-vpn.yml up -d

echo
echo "⏳ Waiting for services to start..."
sleep 15

# Check if encrypted services are accessible
echo "🔍 Checking encrypted service health..."

FIREFOX_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" https://localhost:3443 || echo "000")
QB_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" https://localhost:8443 || echo "000")

if [ "$FIREFOX_STATUS" = "200" ]; then
    echo "✅ Firefox (TLS): https://localhost:3443 (Ready)"
else
    echo "🔄 Firefox (TLS): https://localhost:3443 (Starting...)"
fi

if [ "$QB_STATUS" = "200" ] || [ "$QB_STATUS" = "401" ]; then
    echo "✅ qBittorrent (TLS): https://localhost:8443 (Ready)"
else
    echo "🔄 qBittorrent (TLS): https://localhost:8443 (Starting...)"
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