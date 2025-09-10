#!/bin/bash

# MCP Server Infrastructure Setup Script
# Run this on your Ubuntu server after cloning the repo

set -e

echo "🚀 Setting up MCP Server Infrastructure..."

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
echo "🐳 Building Docker containers..."
docker-compose build

echo "🔄 Starting MCP servers..."
docker-compose up -d

# Install systemd service
echo "⚙️ Installing systemd service..."
cp systemd/mcp-servers.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable mcp-servers

echo "✅ Verifying installation..."
docker ps | grep mcp-

echo ""
echo "✨ Setup complete!"
echo ""
echo "📍 MCP Filesystem Server: http://localhost:3001"
echo ""
echo "🔧 To access from your Mac:"
echo "   ssh -L 3001:localhost:3001 root@134.199.159.190"
echo ""
echo "📊 To view logs:"
echo "   docker-compose logs -f"
echo ""
