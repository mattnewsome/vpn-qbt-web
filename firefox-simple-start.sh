#!/bin/bash

set -e

echo "Starting simplified Firefox container..."

# For now, just create a simple HTTP server that shows Firefox is ready
# This allows us to test the VPN routing without complex VNC setup
cd /home/firefox

cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Firefox Container Ready</title>
</head>
<body>
    <h1>Firefox Container is Running</h1>
    <p>Firefox is installed and ready at: /opt/firefox/firefox</p>
    <p>Container is routing through VPN</p>
    <p>Once VPN is working, we can add VNC access</p>
</body>
</html>
EOF

# Start simple HTTP server on port 3000
echo "Starting HTTP server on port 3000..."
python3 -m http.server 3000