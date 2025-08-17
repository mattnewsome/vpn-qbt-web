# Secure VPN Torrent & Browser Setup

A secure containerized setup that routes Firefox and qBittorrent traffic through NordVPN without affecting your host network.

## 🏗️ Architecture

- **VPN Container**: Custom Red Hat RHEL 9 + official NordVPN client
- **Firefox Container**: LinuxServer Firefox with web UI access
- **qBittorrent Container**: LinuxServer qBittorrent with web UI access
- **Network Isolation**: All Firefox/qBittorrent traffic routes through VPN container
- **Host Protection**: Your host network remains completely unaffected

## ✨ Features

- 🔒 **Secure VPN routing** - All torrent and browser traffic goes through NordVPN
- 🛡️ **Network isolation** - Host network is never affected
- 🔐 **Encrypted inter-container traffic** - TLS encryption protects against host-level sniffing
- 🔍 **Trusted base images** - Red Hat RHEL 9 + official NordVPN client
- 🌐 **Web interfaces** - Access Firefox and qBittorrent through your browser (HTTP + HTTPS)
- 📊 **Health monitoring** - Built-in scripts to check VPN status
- 🚀 **Easy management** - Simple scripts to start/stop/restart everything

## 🚀 Quick Start

### 1. Prerequisites

You need access to Red Hat container images. If you don't have a Red Hat account:
1. **Create free account**: Go to https://developers.redhat.com/
2. **Login to registry**: The start script will prompt you to login if needed

### 2. Set up credentials

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your NordVPN access token
# Get your token from: https://my.nordaccount.com/dashboard/nordvpn/
```

Your `.env` file should look like:
```
NORDVPN_TOKEN=your_actual_access_token_here
NORDVPN_COUNTRY=United_States
LOCAL_NETWORK=10.0.0.0/8,172.16.0.0/12
```

### 3. Start everything

```bash
./start-everything.sh
```

The script will automatically:
- Check if you're logged into Red Hat registry (prompts login if needed)
- Build the custom NordVPN container
- Start all services

### 4. Access your services

**🔒 Encrypted Access Only (for security):**
- **Firefox**: https://localhost:3443
- **qBittorrent**: https://localhost:8443

> 🔒 **Security Note**: Only HTTPS endpoints are exposed to prevent host-level traffic sniffing. HTTP endpoints are disabled for security. Your browser will show a security warning for the self-signed certificate - this is normal and expected. Click "Advanced" → "Proceed to localhost" to continue.

## 🛠️ Management Scripts

| Script | Purpose |
|--------|---------|
| `./start-everything.sh` | Start all containers (first time or after stop) |
| `./restart-everything.sh` | Restart everything (when something breaks) |
| `./stop-everything.sh` | Stop all containers |
| `./check-vpn-status.sh` | Detailed health check and VPN status |

## 📊 Monitoring

### Quick health check
```bash
./check-vpn-status.sh
```

### Check VPN connection manually
```bash
podman exec nordvpn nordvpn status
```

### Check your VPN IP address
```bash
podman exec nordvpn curl -s ifconfig.me
```

### Verify traffic routing
```bash
# Your host IP (should be different from VPN IP)
curl -s ifconfig.me

# Firefox IP (should match VPN IP)
podman exec firefox curl -s ifconfig.me

# qBittorrent IP (should match VPN IP)
podman exec qbittorrent curl -s ifconfig.me
```

## 📁 File Structure

```
.
├── README.md                    # This file
├── .env.example                 # Environment template
├── .env                         # Your credentials (create this)
├── compose-vpn.yml              # Docker Compose configuration
├── Dockerfile.nordvpn           # Custom NordVPN container
├── nordvpn-simple-start.sh      # VPN startup script
├── start-everything.sh          # Start all services
├── stop-everything.sh           # Stop all services  
├── restart-everything.sh        # Restart all services
├── check-vpn-status.sh          # Health monitoring
├── config/                      # qBittorrent configuration
├── downloads/                   # Downloaded files (accessible from host)
└── firefox-config/              # Firefox configuration
```

## 🔧 Configuration

### NordVPN Settings

The VPN container automatically configures:
- **Technology**: NordLynx (fastest)
- **Protocol**: UDP
- **Kill switch**: Disabled (for container compatibility)
- **Analytics**: Disabled

### Firefox Settings

- **Resolution**: 1600x1200 (adjustable in `compose-vpn.yml`)
- **User ID**: Matches your host user (501:20)
- **Config**: Persistent in `./firefox-config/`

### qBittorrent Settings

- **Web UI**: Port 8080
- **Downloads**: Saved to `./downloads/` (accessible from host)
- **User ID**: Matches your host user (501:20)
- **Config**: Persistent in `./config/`

## 🚨 Troubleshooting

### VPN not connecting
```bash
# Check VPN container logs
podman logs nordvpn --tail=20

# Restart everything
./restart-everything.sh

# Verify your token is correct
grep NORDVPN_TOKEN .env
```

### Services not accessible
```bash
# Check all container status
podman ps

# Check specific service logs
podman logs firefox --tail=10
podman logs qbittorrent --tail=10

# Wait longer for startup (VPN can take 60+ seconds)
sleep 60 && ./check-vpn-status.sh
```

### Downloads not appearing
- Files are saved to `./downloads/` directory
- Check permissions: `ls -la downloads/`
- Verify qBittorrent settings in web UI

### Firefox display too small/large
Edit `compose-vpn.yml` and change:
```yaml
environment:
  - CUSTOM_WIDTH=1600    # Adjust width
  - CUSTOM_HEIGHT=1200   # Adjust height
```
Then restart: `./restart-everything.sh`

## 🔐 Security Notes

- ✅ **VPN traffic isolation**: Only Firefox/qBittorrent use VPN
- ✅ **Host network protection**: Your host IP never exposed
- ✅ **Encrypted inter-container traffic**: TLS tunnels protect against host-level sniffing
- ✅ **Trusted base images**: Red Hat RHEL 9 + official clients
- ✅ **No third-party VPN containers**: Built from scratch with official NordVPN
- ✅ **Kill switch protection**: VPN disconnection blocks all traffic
- ⚠️ **Privileged VPN container**: Required for network configuration
- 🔑 **Certificate security**: TLS certificates auto-generated and stored locally
- 🔑 **Token security**: Keep your `.env` file private

### Encryption Details

The system provides **two layers of security**:

1. **VPN Encryption**: All external traffic encrypted via NordVPN tunnel
2. **Inter-Container Encryption**: Internal traffic encrypted via TLS tunnels

This protects against:
- **External network sniffing** (ISP, network admins)
- **Host-level traffic analysis** (malware, compromised host)
- **Container-to-container eavesdropping**

## 📋 System Requirements

- **OS**: macOS with Podman
- **RAM**: 4GB+ recommended
- **Disk**: 1GB+ for containers, space for downloads
- **Network**: Internet connection for VPN
- **Accounts**: Active NordVPN subscription

## 💡 Tips

- **First startup**: Can take 2-3 minutes for VPN to fully connect
- **IP verification**: Always check your IP matches VPN after startup
- **Download location**: Files go to `./downloads/` and are immediately accessible from host
- **Persistence**: Configuration and downloads survive container restarts
- **Firefox bookmarks**: Saved in `./firefox-config/` directory
- **qBittorrent settings**: Saved in `./config/` directory

## 🆘 Support

If something isn't working:

1. Run `./check-vpn-status.sh` for diagnostics
2. Check container logs: `podman logs <container-name>`
3. Try restarting: `./restart-everything.sh`
4. Verify your `.env` file has the correct NordVPN token
5. Ensure your NordVPN subscription is active

---

🎉 **You're all set!** Your Firefox and qBittorrent traffic is now securely routed through NordVPN while keeping your host network completely isolated and protected.