# Claude Desktop MCP Configuration

**Instructions for connecting Claude Desktop to your always-on MCP servers.**

## Prerequisites

- Claude Desktop app installed on your Mac
- SSH access to your server (134.199.159.190)
- MCP servers running (follow README.md setup first)

## Step 1: Create SSH Tunnel

Open Terminal on your Mac and create an SSH tunnel:

```bash
ssh -L 3001:localhost:3001 root@134.199.159.190
```

Keep this terminal window open while using Claude Desktop.

## Step 2: Configure Claude Desktop

1. Open Claude Desktop
2. Go to **Settings** → **Developer** → **MCP Settings**
3. Click **Edit Config** (this opens `~/Library/Application Support/Claude/claude_desktop_config.json`)

## Step 3: Add MCP Server Configuration

Add this to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": ["/path/to/local/mcp-client.js"],
      "env": {
        "MCP_SERVER_URL": "http://localhost:3001",
        "MCP_SERVER_TYPE": "filesystem"
      }
    }
  }
}
```

**Alternative: Direct HTTP Configuration** (if supported in your Claude version):

```json
{
  "mcpServers": {
    "filesystem": {
      "transport": "http",
      "url": "http://localhost:3001",
      "capabilities": {
        "tools": {
          "enabled": true,
          "endpoints": {
            "list": "/mcp/list",
            "read": "/mcp/read",
            "write": "/mcp/write",
            "delete": "/mcp/delete"
          }
        }
      }
    }
  }
}
```

## Step 4: Create Local MCP Client (if needed)

If Claude Desktop doesn't support direct HTTP transport, create this local client:

Create `~/mcp-client.js`:

```javascript
#!/usr/bin/env node

const http = require('http');
const readline = require('readline');

const SERVER_URL = process.env.MCP_SERVER_URL || 'http://localhost:3001';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// MCP Protocol Handler
async function handleRequest(request) {
  const { method, params } = request;
  
  switch(method) {
    case 'tools/list':
      return {
        tools: [
          { name: 'list_files', description: 'List files in directory' },
          { name: 'read_file', description: 'Read file contents' },
          { name: 'write_file', description: 'Write content to file' },
          { name: 'delete_file', description: 'Delete file or directory' }
        ]
      };
      
    case 'tools/call':
      return callTool(params.name, params.arguments);
      
    default:
      throw new Error(`Unknown method: ${method}`);
  }
}

async function callTool(toolName, args) {
  const endpoints = {
    'list_files': '/mcp/list',
    'read_file': '/mcp/read',
    'write_file': '/mcp/write',
    'delete_file': '/mcp/delete'
  };
  
  const endpoint = endpoints[toolName];
  if (!endpoint) {
    throw new Error(`Unknown tool: ${toolName}`);
  }
  
  const response = await fetch(`${SERVER_URL}${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(args)
  });
  
  return await response.json();
}

// Main loop
rl.on('line', async (line) => {
  try {
    const request = JSON.parse(line);
    const response = await handleRequest(request);
    console.log(JSON.stringify({ 
      jsonrpc: '2.0',
      id: request.id,
      result: response 
    }));
  } catch (error) {
    console.log(JSON.stringify({ 
      jsonrpc: '2.0',
      id: request.id,
      error: { message: error.message }
    }));
  }
});
```

Make it executable:
```bash
chmod +x ~/mcp-client.js
```

Update the config to point to this file:
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": ["/Users/YOUR_USERNAME/mcp-client.js"],
      "env": {
        "MCP_SERVER_URL": "http://localhost:3001"
      }
    }
  }
}
```

## Step 5: Restart Claude Desktop

1. Quit Claude Desktop completely (Cmd+Q)
2. Start Claude Desktop again
3. Check **Settings** → **Developer** → **MCP Settings** to verify server is connected

## Step 6: Test the Connection

In Claude, try these commands:

```
"List files on the server"
"Create a file called test.txt with content 'Hello from Claude'"
"Read the contents of test.txt"
```

## Troubleshooting

### SSH Tunnel Closed
If Claude can't connect, check your SSH tunnel is still running:
```bash
# Check if tunnel is active
ps aux | grep "ssh -L 3001"

# Restart tunnel if needed
ssh -L 3001:localhost:3001 root@134.199.159.190
```

### Server Not Responding
Check server status:
```bash
# SSH into server
ssh root@134.199.159.190

# Check Docker containers
docker ps | grep mcp-

# View logs
docker logs mcp-filesystem --tail 50
```

### Claude Not Detecting MCP
1. Verify config file is valid JSON (use jsonlint.com)
2. Check Claude Desktop logs: `~/Library/Logs/Claude/`
3. Try simpler config first, then add features

## Advanced: Auto-start SSH Tunnel

Create `~/Library/LaunchAgents/com.mcp.tunnel.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mcp.tunnel</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/ssh</string>
        <string>-N</string>
        <string>-L</string>
        <string>3001:localhost:3001</string>
        <string>root@134.199.159.190</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.mcp.tunnel.plist
```

Now the tunnel auto-starts when you login!

## Adding More MCP Servers

For each new server you add to the infrastructure:

1. Add new port to SSH tunnel: `ssh -L 3001:localhost:3001 -L 3002:localhost:3002 root@134.199.159.190`
2. Add new entry to `claude_desktop_config.json`
3. Restart Claude Desktop

## Security Notes

- SSH tunnel is encrypted end-to-end
- No ports exposed to internet
- Only you can access via your SSH key
- Consider SSH key-only auth (disable password auth on server)

## Support

- Check server README: https://github.com/harrysayers7/mcp-server-infra
- View server logs: `docker-compose logs -f` (on server)
- Test endpoints: Run `./scripts/test.sh` (on server)
