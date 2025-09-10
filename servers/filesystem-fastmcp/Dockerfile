FROM python:3.11-slim

WORKDIR /app

# Install FastMCP
RUN pip install --no-cache-dir fastmcp

# Copy server code
COPY server.py .

# Create data directory
RUN mkdir -p /data

# Set permissions
RUN chmod +x server.py

EXPOSE 3000

# Run the server
CMD ["python", "server.py", "3000"]
