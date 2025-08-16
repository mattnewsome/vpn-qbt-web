#!/bin/bash

# Exit on any error
set -e

echo "Starting qBittorrent..."

# Set up configuration directory
mkdir -p /config/qBittorrent
mkdir -p /downloads

# Create basic qBittorrent configuration if it doesn't exist
if [ ! -f /config/qBittorrent/qBittorrent.conf ]; then
    echo "Creating initial qBittorrent configuration..."
    cat > /config/qBittorrent/qBittorrent.conf << EOF
[BitTorrent]
Session\DefaultSavePath=/downloads
Session\TempPath=/downloads/incomplete

[Preferences]
WebUI\Port=${QBT_WEBUI_PORT:-8080}
WebUI\Address=*
WebUI\LocalHostAuth=false
WebUI\Username=admin
WebUI\Password_PBKDF2="@ByteArray(ARQ77eY1NUZaQsuDHbIMCA==:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR1Gur2hmQCvCDpm39Q+PsJRJPaCU51dEiz+dTzh8qbPsL8WkFljQYFQ==)"

[Network]
Proxy\OnlyForTorrents=false
EOF
fi

# Start qBittorrent
echo "Starting qBittorrent daemon..."
exec /usr/bin/qbittorrent-nox \
    --profile=/config \
    --webui-port=${QBT_WEBUI_PORT:-8080}