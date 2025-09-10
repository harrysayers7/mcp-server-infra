# Claude Code Deployment Instructions

**Copy these instructions to Claude Code in Cursor for automated deployment.**

## Primary Deployment Command

```
Deploy the FastMCP infrastructure from https://github.com/harrysayers7/mcp-server-infra.git to server 134.199.159.190

CRITICAL RULES:
1. Use docker-compose (with hyphen), NOT "docker compose"
2. Always use full paths: /opt/mcp-server-infra
3. Check if repo exists before cloning
4. Use FastMCP version (setup-fastmcp.sh) not the basic HTTP version

DEPLOYMENT STEPS:
1. SSH into root@134.199.159.190
2. Check if /opt/mcp-server-infra exists, if yes: cd into it and git pull
3. If not exists: cd /opt && git clone https://github.com/harrysayers7/mcp-server-infra.git
4. cd /opt/mcp-server-infra
5. Run: chmod +x scripts/setup-fastmcp.sh && ./scripts/setup-fastmcp.sh
6. Verify with: docker ps | grep fastmcp
7. Test with: ./scripts/test-fastmcp.sh
8. Show systemd status: systemctl status mcp-fastmcp-servers

EXPECTED OUTPUT:
- Container mcp-filesystem-fastmcp should be running on port 3001
- Systemd service should be enabled
- Test script should show SSE endpoint responding
```

## Adding New MCP Server

```
Add a new MCP server called [SERVICE_NAME] to the infrastructure at /opt/mcp-server-infra

RULES:
1. Use FastMCP pattern from existing filesystem-fastmcp example
2. Assign next available port (3002, 3003, etc)
3. Create proper Dockerfile with Python 3.11-slim base
4. Update docker-compose-fastmcp.yml
5. Test before confirming deployment

STEPS:
1. SSH into root@134.199.159.190
2. cd /opt/mcp-server-infra
3. Create servers/[SERVICE_NAME]/server.py using FastMCP pattern
4. Create servers/[SERVICE_NAME]/Dockerfile
5. Add service to docker-compose-fastmcp.yml with port 300X:3000
6. Run: docker-compose -f docker-compose-fastmcp.yml up -d --build [SERVICE_NAME]
7. Verify: docker logs mcp-[SERVICE_NAME]
8. Test endpoint: curl http://localhost:300X/sse
```

## Updating Existing Server

```
Update the [SERVICE_NAME] MCP server in /opt/mcp-server-infra

STEPS:
1. SSH into root@134.199.159.190
2. cd /opt/mcp-server-infra
3. Edit servers/[SERVICE_NAME]/server.py
4. Rebuild: docker-compose -f docker-compose-fastmcp.yml build [SERVICE_NAME]
5. Restart: docker-compose -f docker-compose-fastmcp.yml up -d [SERVICE_NAME]
6. Verify: docker logs mcp-[SERVICE_NAME] --tail 50
```

## Troubleshooting Commands

```
If deployment fails, debug the MCP infrastructure on 134.199.159.190

DIAGNOSTIC STEPS:
1. Check containers: docker ps -a | grep mcp
2. View logs: docker logs [CONTAINER_NAME] --tail 100
3. Check ports: netstat -tlnp | grep 300
4. Test health: curl http://localhost:3001/health
5. Check systemd: systemctl status mcp-fastmcp-servers
6. View compose logs: docker-compose -f docker-compose-fastmcp.yml logs --tail 50
7. Restart everything: docker-compose -f docker-compose-fastmcp.yml restart

COMMON FIXES:
- Port conflict: Change port in docker-compose-fastmcp.yml
- Build cache: docker-compose -f docker-compose-fastmcp.yml build --no-cache
- Permission issue: chmod -R 755 /opt/mcp-data
- Clean restart: docker-compose -f docker-compose-fastmcp.yml down && docker-compose -f docker-compose-fastmcp.yml up -d
```

## Monitoring Health

```
Check health status of MCP infrastructure on 134.199.159.190

COMMANDS:
1. Overall status: docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
2. Resource usage: docker stats --no-stream
3. Disk usage: df -h /opt/mcp-data
4. Recent logs: docker-compose -f docker-compose-fastmcp.yml logs --tail 20 --timestamps
5. Test endpoints:
   - curl http://localhost:3001/health
   - curl http://localhost:3001/sse
```

## Full Reset

```
Completely reset and redeploy MCP infrastructure on 134.199.159.190

WARNING: This will delete all data in /opt/mcp-data

STEPS:
1. SSH into root@134.199.159.190
2. Stop services: docker-compose -f /opt/mcp-server-infra/docker-compose-fastmcp.yml down
3. Remove containers: docker container prune -f
4. Clean data: rm -rf /opt/mcp-data/*
5. Pull latest: cd /opt/mcp-server-infra && git pull
6. Rebuild: ./scripts/setup-fastmcp.sh
7. Verify: docker ps | grep fastmcp
```

## Important Context for Claude Code

### Server Details
- IP: 134.199.159.190
- OS: Ubuntu 22.04
- Docker: Installed with docker-compose (hyphen version)
- Project Location: /opt/mcp-server-infra
- Data Location: /opt/mcp-data/

### Port Assignments
- 3001: filesystem-fastmcp
- 3002: (next available)
- 3003: (next available)
- All ports bind to 127.0.0.1 only (SSH tunnel required for external access)

### File Structure
```
/opt/mcp-server-infra/
├── docker-compose-fastmcp.yml    # Main orchestration file
├── servers/                       # MCP server implementations
│   └── filesystem-fastmcp/       # Example FastMCP server
│       ├── server.py
│       └── Dockerfile
├── scripts/                       # Automation scripts
│   ├── setup-fastmcp.sh          # Initial setup
│   └── test-fastmcp.sh           # Testing script
└── systemd/                       # Boot persistence
```

### Common Issues Claude Code Should Handle
1. Check if directory exists before mkdir
2. Check if container is running before starting
3. Use absolute paths always
4. Handle git pull conflicts gracefully
5. Verify Docker daemon is running
6. Check disk space before operations

### Expected Success Indicators
- `docker ps` shows containers with "Up" status
- No errors in `docker logs`
- SSE endpoint responds to curl
- Systemd service is "enabled"
- Test script completes without errors

## DO NOT:
- Use "docker compose" (space) - always use "docker-compose" (hyphen)
- Expose ports publicly - keep 127.0.0.1 binding
- Delete /opt/mcp-data without confirmation
- Modify systemd services without backup
- Change port bindings without checking conflicts
- Run as non-root user (containers need root for port binding)

## ALWAYS:
- Verify each step before proceeding
- Show command output for verification
- Use absolute paths
- Check service health after changes
- Keep data directory permissions at 755
- Maintain port documentation when adding services
