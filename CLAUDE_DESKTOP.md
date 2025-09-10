# Claude Desktop Setup

**How to connect Claude Desktop app to your MCP servers.**

## Prerequisites
- Claude Desktop app installed
- MCP servers deployed and running on your server
- SSH access to your server

## Step 1: Create SSH Tunnel

Open Terminal on your Mac and run:

```bash
ssh -L 3001:localhost:3001 root@134.199.159.190
```

Keep this terminal open while using Claude Desktop.

For multiple services:
```bash
ssh -L 3001:localhost:3001 -L 3002:localhost:3002 -L 3003:localhost:3003 root@134.199.159.190
```

## Step 2: Configure Claude Desktop

1. Open Claude Desktop
2. Go to **Settings** → **Developer** → **MCP Settings**
3. Click **Edit Config**

This opens: `~/Library/Application Support/Claude/claude_desktop_config.json`

## Step 3: Add MCP Configuration

Add this configuration for FastMCP servers:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-sse-client",
        "http://localhost:3001/sse"
      ]
    }
  }
}
```

For multiple servers:
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-sse-client",
        "http://localhost:3001/sse"
      ]
    },
    "weather": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-sse-client",
        "http://localhost:3002/sse"
      ]
    },
    "database": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-sse-client",
        "http://localhost:3003/sse"
      ]
    }
  }
}
```

## Step 4: Install SSE Client

The SSE client needs to be installed once:

```bash
npm install -g @modelcontextprotocol/server-sse-client
```

## Step 5: Restart Claude Desktop

1. Completely quit Claude Desktop (Cmd+Q)
2. Start Claude Desktop again
3. Check MCP is connected in settings

## Testing the Connection

In Claude Desktop, try:
- "List files on the server using the filesystem tool"
- "Create a test file called hello.txt"
- "Read the contents of hello.txt"

## Auto-start SSH Tunnel (Optional)

Create `~/mcp-tunnel.sh`:

```bash
#!/bin/bash
ssh -N -L 3001:localhost:3001 -L 3002:localhost:3002 -L 3003:localhost:3003 \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    root@134.199.159.190
```

Make it executable:
```bash
chmod +x ~/mcp-tunnel.sh
```

Create LaunchAgent `~/Library/LaunchAgents/com.mcp.tunnel.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mcp.tunnel</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/mcp-tunnel.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>StandardErrorPath</key>
    <string>/tmp/mcp-tunnel.err</string>
    <key>StandardOutPath</key>
    <string>/tmp/mcp-tunnel.out</string>
</dict>
</plist>
```

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.mcp.tunnel.plist
```

## Troubleshooting

### Claude doesn't see MCP servers
1. Check SSH tunnel is running: `ps aux | grep ssh`
2. Verify JSON syntax in config file
3. Restart Claude Desktop completely

### Connection errors
1. Test SSE endpoint: `curl http://localhost:3001/sse`
2. Check server logs: `ssh root@134.199.159.190 'docker logs mcp-filesystem-fastmcp'`
3. Verify port forwarding: `netstat -an | grep 3001`

### Tools not working
1. Check npx is installed: `which npx`
2. Install SSE client globally: `npm install -g @modelcontextprotocol/server-sse-client`
3. Check Claude Desktop logs: `~/Library/Logs/Claude/`

## Port Reference

| Service | Local Port | Server Port | SSE Endpoint |
|---------|------------|-------------|--------------|
| filesystem | 3001 | 3001 | http://localhost:3001/sse |
| weather | 3002 | 3002 | http://localhost:3002/sse |
| database | 3003 | 3003 | http://localhost:3003/sse |

## Security Notes

- SSH tunnel is encrypted end-to-end
- No ports exposed to internet
- Only accessible with your SSH key
- Consider using SSH config for easier connections:

Add to `~/.ssh/config`:
```
Host mcp-server
    HostName 134.199.159.190
    User root
    LocalForward 3001 localhost:3001
    LocalForward 3002 localhost:3002
    LocalForward 3003 localhost:3003
    ServerAliveInterval 60
```

Then connect with just: `ssh mcp-server`

## Additional Resources

- [MCP Documentation](https://modelcontextprotocol.io)
- [Server Repository](https://github.com/harrysayers7/mcp-server-infra)
- Server Logs: `ssh root@134.199.159.190 'docker-compose -f /opt/mcp-server-infra/docker-compose-fastmcp.yml logs'`
