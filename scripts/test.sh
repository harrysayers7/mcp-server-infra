#!/bin/bash

# Test script to verify MCP servers are working

echo "🧪 Testing MCP Filesystem Server..."
echo ""

# Test health endpoint
echo "1. Testing health check..."
curl -s http://localhost:3001/health | python3 -m json.tool
echo ""

# Test MCP info
echo "2. Getting MCP info..."
curl -s http://localhost:3001/mcp/info | python3 -m json.tool
echo ""

# Test write operation
echo "3. Writing test file..."
curl -s -X POST http://localhost:3001/mcp/write \
  -H "Content-Type: application/json" \
  -d '{"path": "test.txt", "content": "Hello from MCP!"}' | python3 -m json.tool
echo ""

# Test list operation
echo "4. Listing files..."
curl -s -X POST http://localhost:3001/mcp/list \
  -H "Content-Type: application/json" \
  -d '{"path": "/"}' | python3 -m json.tool
echo ""

# Test read operation
echo "5. Reading test file..."
curl -s -X POST http://localhost:3001/mcp/read \
  -H "Content-Type: application/json" \
  -d '{"path": "test.txt"}' | python3 -m json.tool
echo ""

echo "✅ Tests complete!"
