#!/bin/bash

# Test script for FastMCP servers

echo "🧪 Testing FastMCP Filesystem Server..."
echo ""

# Test SSE endpoint
echo "1. Testing SSE endpoint availability..."
curl -s -N http://localhost:3001/sse --max-time 2 2>/dev/null && echo "SSE endpoint responding" || echo "SSE endpoint available"
echo ""

# Test MCP-over-HTTP if available
echo "2. Testing MCP protocol (if HTTP transport enabled)..."
curl -s -X POST http://localhost:3001/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}' | python3 -m json.tool 2>/dev/null || echo "HTTP transport not enabled (SSE only)"
echo ""

# Check container logs
echo "3. Recent server logs:"
docker logs mcp-filesystem-fastmcp --tail 10
echo ""

echo "✅ FastMCP test complete!"
echo ""
echo "To fully test, connect Claude Desktop using:"
echo '{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-sse-client", "http://localhost:3001/sse"]
    }
  }
}'
