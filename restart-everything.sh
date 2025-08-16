#!/bin/bash

# Restart the VPN stack
# This script stops everything cleanly, then starts it all back up

set -e

echo "🔄 Restarting VPN stack..."
echo

# Stop everything first
echo "🛑 Step 1: Stopping everything..."
./stop-everything.sh

echo
echo "🚀 Step 2: Starting everything..."
./start-everything.sh

echo
echo "🔄 Restart complete!"