#!/bin/bash

set -e

echo "Starting Firefox container..."

# Set up display
export DISPLAY=:1

# Start Xvfb
echo "Starting Xvfb..."
Xvfb :1 -screen 0 1024x768x24 &
sleep 2

# Start x11vnc
echo "Starting VNC server..."
x11vnc -display :1 -nopw -listen localhost -xkb -ncache 10 -ncache_cr -forever &
sleep 2

# Start noVNC websocket proxy
echo "Starting noVNC..."
cd /opt/novnc
python3 utils/websockify/websockify.py --web . 3000 localhost:5901 &
sleep 2

# Start Firefox
echo "Starting Firefox..."
export HOME=/home/firefox
exec firefox --display=:1 --no-sandbox