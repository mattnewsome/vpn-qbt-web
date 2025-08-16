#!/bin/bash

# VPN Container Health Check Script
# Monitors NordVPN container status and connection health

set -e

CONTAINER_NAME="nordvpn"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== VPN Container Health Check ===${NC}"
echo "Timestamp: $(date)"
echo

# Check if container is running
echo -e "${BLUE}Container Status:${NC}"
if podman ps --filter name=${CONTAINER_NAME} --format "{{.Names}}" | grep -q ${CONTAINER_NAME}; then
    CONTAINER_STATUS=$(podman ps --filter name=${CONTAINER_NAME} --format "{{.Status}}")
    echo -e "${GREEN}✓${NC} Container '${CONTAINER_NAME}' is running (${CONTAINER_STATUS})"
else
    echo -e "${RED}✗${NC} Container '${CONTAINER_NAME}' is not running"
    echo -e "${YELLOW}Overall Status: FAILED - Container not running${NC}"
    exit 1
fi

echo

# Check VPN daemon status
echo -e "${BLUE}VPN Connection Status:${NC}"
VPN_STATUS_OUTPUT=$(podman exec ${CONTAINER_NAME} nordvpn status 2>/dev/null || echo "FAILED")

if [[ "$VPN_STATUS_OUTPUT" == "FAILED" ]]; then
    echo -e "${RED}✗${NC} Cannot reach NordVPN daemon"
    echo -e "${YELLOW}Overall Status: FAILED - Daemon not responding${NC}"
    exit 1
fi

echo "$VPN_STATUS_OUTPUT"
echo

# Check if connected
if echo "$VPN_STATUS_OUTPUT" | grep -q "Status: Connected"; then
    VPN_CONNECTED=true
    echo -e "${GREEN}✓${NC} VPN is connected"
else
    VPN_CONNECTED=false
    echo -e "${RED}✗${NC} VPN is not connected"
fi

echo

# Get IP addresses
echo -e "${BLUE}IP Address Information:${NC}"

# Host IP
HOST_IP=$(curl -s --max-time 10 ifconfig.me || echo "Unable to fetch")
echo "Host IP:      ${HOST_IP}"

# VPN IP
VPN_IP=$(podman exec ${CONTAINER_NAME} curl -s --max-time 10 ifconfig.me 2>/dev/null || echo "Unable to fetch")
echo "VPN IP:       ${VPN_IP}"

# Firefox container IP (if accessible)
FIREFOX_IP=$(podman exec firefox curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "Unable to fetch")
echo "Firefox IP:   ${FIREFOX_IP}"

# qBittorrent container IP (if accessible)
QB_IP=$(podman exec qbittorrent curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "Unable to fetch")
echo "qBittorrent IP: ${QB_IP}"

echo

# Traffic routing verification
echo -e "${BLUE}Traffic Routing Verification:${NC}"
if [[ "$VPN_IP" != "Unable to fetch" && "$HOST_IP" != "Unable to fetch" ]]; then
    if [[ "$VPN_IP" != "$HOST_IP" ]]; then
        echo -e "${GREEN}✓${NC} VPN traffic is properly routed (different from host)"
    else
        echo -e "${RED}✗${NC} VPN traffic may not be routed properly (same as host)"
    fi
else
    echo -e "${YELLOW}?${NC} Cannot verify traffic routing (IP fetch failed)"
fi

if [[ "$FIREFOX_IP" == "$VPN_IP" ]]; then
    echo -e "${GREEN}✓${NC} Firefox traffic is routing through VPN"
else
    echo -e "${YELLOW}?${NC} Firefox traffic routing unclear (IP: ${FIREFOX_IP})"
fi

if [[ "$QB_IP" == "$VPN_IP" ]]; then
    echo -e "${GREEN}✓${NC} qBittorrent traffic is routing through VPN"
else
    echo -e "${YELLOW}?${NC} qBittorrent traffic routing unclear (IP: ${QB_IP})"
fi

echo

# Account information
echo -e "${BLUE}Account Information:${NC}"
ACCOUNT_INFO=$(podman exec ${CONTAINER_NAME} nordvpn account 2>/dev/null || echo "Unable to fetch account info")
echo "$ACCOUNT_INFO"

echo

# Overall health summary
echo -e "${BLUE}=== OVERALL HEALTH SUMMARY ===${NC}"

if [[ "$VPN_CONNECTED" == true && "$VPN_IP" != "Unable to fetch" && "$VPN_IP" != "$HOST_IP" ]]; then
    echo -e "${GREEN}STATUS: HEALTHY${NC}"
    echo -e "${GREEN}✓${NC} Container running"
    echo -e "${GREEN}✓${NC} VPN connected" 
    echo -e "${GREEN}✓${NC} Traffic properly routed"
    echo -e "Current VPN IP: ${GREEN}${VPN_IP}${NC}"
    
    # Extract server info from status
    SERVER_INFO=$(echo "$VPN_STATUS_OUTPUT" | grep "Server:" | cut -d' ' -f2- || echo "Unknown")
    LOCATION=$(echo "$VPN_STATUS_OUTPUT" | grep "Country:" | cut -d' ' -f2- || echo "Unknown")
    echo -e "Connected to: ${GREEN}${SERVER_INFO}${NC} (${LOCATION})"
else
    echo -e "${RED}STATUS: UNHEALTHY${NC}"
    
    if [[ "$VPN_CONNECTED" != true ]]; then
        echo -e "${RED}✗${NC} VPN not connected"
    fi
    
    if [[ "$VPN_IP" == "Unable to fetch" ]]; then
        echo -e "${RED}✗${NC} Cannot determine VPN IP"
    elif [[ "$VPN_IP" == "$HOST_IP" ]]; then
        echo -e "${RED}✗${NC} Traffic not routing through VPN"
    fi
    
    echo -e "Current IP: ${RED}${VPN_IP:-Unknown}${NC}"
fi

echo
echo "Services accessible at:"
echo "  Firefox:    http://localhost:3000"
echo "  qBittorrent: http://localhost:8080"