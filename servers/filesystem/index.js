const express = require('express');
const cors = require('cors');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const DATA_DIR = '/data';

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'mcp-filesystem', uptime: process.uptime() });
});

// MCP Protocol Info
app.get('/mcp/info', (req, res) => {
  res.json({
    name: 'filesystem',
    version: '1.0.0',
    capabilities: ['read', 'write', 'list', 'delete'],
    description: 'MCP server for filesystem operations'
  });
});

// List files in directory
app.post('/mcp/list', async (req, res) => {
  try {
    const { path: dirPath = '/' } = req.body;
    const fullPath = path.join(DATA_DIR, dirPath);
    
    const files = await fs.readdir(fullPath, { withFileTypes: true });
    const result = files.map(file => ({
      name: file.name,
      type: file.isDirectory() ? 'directory' : 'file',
      path: path.join(dirPath, file.name)
    }));
    
    res.json({ success: true, files: result });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Read file
app.post('/mcp/read', async (req, res) => {
  try {
    const { path: filePath } = req.body;
    if (!filePath) {
      return res.status(400).json({ success: false, error: 'Path required' });
    }
    
    const fullPath = path.join(DATA_DIR, filePath);
    const content = await fs.readFile(fullPath, 'utf-8');
    
    res.json({ success: true, content });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Write file
app.post('/mcp/write', async (req, res) => {
  try {
    const { path: filePath, content } = req.body;
    if (!filePath || content === undefined) {
      return res.status(400).json({ success: false, error: 'Path and content required' });
    }
    
    const fullPath = path.join(DATA_DIR, filePath);
    const dir = path.dirname(fullPath);
    
    // Create directory if it doesn't exist
    await fs.mkdir(dir, { recursive: true });
    await fs.writeFile(fullPath, content, 'utf-8');
    
    res.json({ success: true, message: 'File written successfully' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Delete file or directory
app.post('/mcp/delete', async (req, res) => {
  try {
    const { path: targetPath } = req.body;
    if (!targetPath) {
      return res.status(400).json({ success: false, error: 'Path required' });
    }
    
    const fullPath = path.join(DATA_DIR, targetPath);
    const stats = await fs.stat(fullPath);
    
    if (stats.isDirectory()) {
      await fs.rmdir(fullPath, { recursive: true });
    } else {
      await fs.unlink(fullPath);
    }
    
    res.json({ success: true, message: 'Deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`MCP Filesystem Server running on port ${PORT}`);
  console.log(`Data directory: ${DATA_DIR}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});
