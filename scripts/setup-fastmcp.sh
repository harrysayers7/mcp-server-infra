#!/bin/bash

# FastMCP Server Infrastructure Setup Script
# Deploys MCP servers using FastMCP (proper MCP protocol)

set -e

echo "🚀 Setting up FastMCP Server Infrastructure..."

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo" 
   exit 1
fi

# Create data directories
echo "📁 Creating data directories..."
mkdir -p /opt/mcp-data/filesystem
chmod -R 755 /opt/mcp-data

# Build and start Docker containers
echo "🐳 Building FastMCP containers..."
docker-compose -f docker-compose-fastmcp.yml build

echo "🔄 Starting FastMCP servers..."
docker-compose -f docker-compose-fastmcp.yml up -d

# Install systemd service
echo "⚙️ Installing systemd service..."
cat > /etc/systemd/system/mcp-fastmcp-servers.service << EOF
[Unit]
Description=FastMCP Servers Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/mcp-server-infra
ExecStart=/usr/bin/docker-compose -f docker-compose-fastmcp.yml up -d
ExecStop=/usr/bin/docker-compose -f docker-compose-fastmcp.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mcp-fastmcp-servers

echo "✅ Verifying installation..."
docker ps | grep fastmcp

echo ""
echo "✨ FastMCP Setup complete!"
echo ""
echo "📍 MCP Filesystem Server (FastMCP): http://localhost:3001"
echo "   SSE Endpoint: http://localhost:3001/sse"
echo ""
echo "🔧 To access from your Mac:"
echo "   ssh -L 3001:localhost:3001 root@134.199.159.190"
echo ""
echo "📦 Claude Desktop config:"
echo '   "filesystem": {'
echo '     "command": "npx",'
echo '     "args": ["@modelcontextprotocol/server-sse-client", "http://localhost:3001/sse"]'
echo '   }'
echo ""
echo "📊 To view logs:"
echo "   docker-compose -f docker-compose-fastmcp.yml logs -f"
echo ""
