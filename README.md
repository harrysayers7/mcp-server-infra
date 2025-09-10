# MCP Server Infrastructure

**Always-on MCP servers running on Ubuntu VPS - accessible 24/7 even when your laptop is closed.**

## Quick Start

```bash
# SSH into your server
ssh root@134.199.159.190

# Clone this repo
cd /opt
git clone https://github.com/harrysayers7/mcp-server-infra.git
cd mcp-server-infra

# Run setup script
chmod +x scripts/setup.sh
./scripts/setup.sh

# Or manually:
docker-compose up -d
```

## Architecture

```
Your Mac/Cursor → SSH Tunnel → Ubuntu Server → Docker Container → MCP Server
                                (Always On)     (Auto-restarts)
```

## Available MCP Servers

### 1. Filesystem MCP (Port 3001)
- **Purpose**: Read/write files on the server
- **Access**: `localhost:3001` via SSH tunnel
- **Data**: Persisted in `/opt/mcp-data/filesystem`

## Accessing from Your Mac

```bash
# Create SSH tunnel (run on your Mac)
ssh -L 3001:localhost:3001 root@134.199.159.190

# Now access MCP at http://localhost:3001 from Cursor/Claude Desktop
```

## Testing

```bash
# Run test script after setup
chmod +x scripts/test.sh
./scripts/test.sh
```

## Auto-start on Boot

The setup script installs a systemd service that ensures MCP servers start when server reboots.

## Adding New MCP Servers

1. Create new folder in `servers/`
2. Add to `docker-compose.yml`
3. Assign unique port (3002, 3003, etc)
4. Run `docker-compose up -d`

## Monitoring

```bash
# View logs
docker-compose logs -f

# Check status
docker ps

# Restart if needed
docker-compose restart
```

## Security Notes

- No public ports exposed (only localhost bindings)
- Access only via SSH tunnel
- Data persisted in `/opt/mcp-data/`
- No auth needed for internal services (add later if exposing publicly)
