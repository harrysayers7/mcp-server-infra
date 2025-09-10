#!/usr/bin/env python3
"""FastMCP Filesystem Server - Proper MCP protocol implementation"""

from fastmcp import FastMCP
from pathlib import Path
import os
import json
from typing import List, Dict, Optional

# Initialize MCP server
mcp = FastMCP("filesystem")

# Base data directory
DATA_DIR = Path("/data")

@mcp.tool()
def list_files(path: str = "/") -> List[Dict[str, str]]:
    """List files and directories at the given path"""
    target_path = DATA_DIR / path.lstrip("/")
    
    if not target_path.exists():
        return [{"error": f"Path {path} does not exist"}]
    
    if not target_path.is_dir():
        return [{"error": f"Path {path} is not a directory"}]
    
    files = []
    for item in target_path.iterdir():
        files.append({
            "name": item.name,
            "type": "directory" if item.is_dir() else "file",
            "path": str(item.relative_to(DATA_DIR))
        })
    
    return files

@mcp.tool()
def read_file(path: str) -> str:
    """Read the contents of a file"""
    target_path = DATA_DIR / path.lstrip("/")
    
    if not target_path.exists():
        return f"Error: File {path} does not exist"
    
    if not target_path.is_file():
        return f"Error: {path} is not a file"
    
    try:
        return target_path.read_text()
    except Exception as e:
        return f"Error reading file: {str(e)}"

@mcp.tool()
def write_file(path: str, content: str) -> str:
    """Write content to a file, creating directories if needed"""
    target_path = DATA_DIR / path.lstrip("/")
    
    try:
        # Create parent directories if they don't exist
        target_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Write the file
        target_path.write_text(content)
        
        return f"Successfully wrote to {path}"
    except Exception as e:
        return f"Error writing file: {str(e)}"

@mcp.tool()
def delete_file(path: str) -> str:
    """Delete a file or empty directory"""
    target_path = DATA_DIR / path.lstrip("/")
    
    if not target_path.exists():
        return f"Error: Path {path} does not exist"
    
    try:
        if target_path.is_dir():
            target_path.rmdir()  # Only removes empty directories
            return f"Successfully deleted directory {path}"
        else:
            target_path.unlink()
            return f"Successfully deleted file {path}"
    except Exception as e:
        return f"Error deleting: {str(e)}"

@mcp.tool()
def create_directory(path: str) -> str:
    """Create a new directory"""
    target_path = DATA_DIR / path.lstrip("/")
    
    try:
        target_path.mkdir(parents=True, exist_ok=True)
        return f"Successfully created directory {path}"
    except Exception as e:
        return f"Error creating directory: {str(e)}"

@mcp.tool()
def file_info(path: str) -> Dict[str, any]:
    """Get detailed information about a file or directory"""
    target_path = DATA_DIR / path.lstrip("/")
    
    if not target_path.exists():
        return {"error": f"Path {path} does not exist"}
    
    stat = target_path.stat()
    
    return {
        "path": path,
        "type": "directory" if target_path.is_dir() else "file",
        "size": stat.st_size,
        "modified": stat.st_mtime,
        "created": stat.st_ctime,
        "permissions": oct(stat.st_mode)[-3:]
    }

if __name__ == "__main__":
    # Ensure data directory exists
    DATA_DIR.mkdir(exist_ok=True)
    
    # Run the server
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 3000
    
    print(f"Starting FastMCP Filesystem Server on port {port}")
    print(f"Data directory: {DATA_DIR}")
    
    # Run with SSE transport for Claude Desktop compatibility
    mcp.run(port=port, transport="sse")
