# MCP Server Infrastructure v2

**Always-on MCP servers using FastMCP - proper MCP protocol implementation.**

## Architecture Change

We're migrating from basic HTTP endpoints to proper MCP protocol using FastMCP:
- ✅ Native Claude Desktop support
- ✅ Proper JSON-RPC 2.0 protocol
- ✅ Automatic tool discovery
- ✅ Type safety with Pydantic

## Quick Start

```bash
# SSH into your server
ssh root@134.199.159.190

# Clone this repo
cd /opt
git clone https://github.com/harrysayers7/mcp-server-infra.git
cd mcp-server-infra

# Choose setup:
./scripts/setup-fastmcp.sh  # New FastMCP servers (recommended)
# OR
./scripts/setup.sh          # Original HTTP servers
```

## FastMCP Servers

### Filesystem Server (Port 3001)
- Proper MCP protocol via FastMCP
- SSE transport for Claude Desktop
- Type-safe operations

### Adding New FastMCP Servers

1. Create `servers/your-service/server.py`:
```python
from fastmcp import FastMCP

mcp = FastMCP("your-service")

@mcp.tool()
def your_tool(param: str) -> str:
    """Tool description"""
    return f"Result: {param}"

if __name__ == "__main__":
    mcp.run(port=3002)
```

2. Create `servers/your-service/Dockerfile`:
```dockerfile
FROM python:3.11-slim
WORKDIR /app
RUN pip install fastmcp
COPY server.py .
CMD ["python", "server.py"]
```

3. Add to `docker-compose-fastmcp.yml`

## Claude Desktop Configuration

### For FastMCP Servers (Recommended):

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

### For Original HTTP Servers:

See CLAUDE.md for HTTP adapter setup.

## Why FastMCP?

1. **Proper MCP Protocol** - Not just HTTP endpoints
2. **Direct Claude Support** - No adapter needed
3. **Type Safety** - Pydantic validation
4. **Tool Discovery** - Automatic schema generation
5. **Better DX** - Decorators instead of boilerplate

## Migration Path

1. Keep existing HTTP servers running
2. Add new servers using FastMCP
3. Gradually migrate old servers
4. Remove HTTP adapter layer

## SSH Tunnel (Same for Both)

```bash
# From your Mac
ssh -L 3001:localhost:3001 -L 3002:localhost:3002 root@134.199.159.190
```

## Next Steps

1. Deploy FastMCP version: `./scripts/setup-fastmcp.sh`
2. Test with: `./scripts/test-fastmcp.sh`
3. Connect Claude Desktop using SSE client
4. Build new services with FastMCP
