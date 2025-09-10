# Building MCP Servers

**How to create new MCP servers for your infrastructure.**

## Quick Example: Weather MCP Server

### 1. Create the Server (FastMCP - Recommended)

Create `servers/weather/server.py`:

```python
from fastmcp import FastMCP
import requests

mcp = FastMCP("weather")

@mcp.tool()
def get_weather(city: str) -> dict:
    """Get current weather for a city"""
    # Your API call here
    response = requests.get(f"https://api.weather.com/{city}")
    return response.json()

@mcp.tool()
def get_forecast(city: str, days: int = 5) -> dict:
    """Get weather forecast"""
    # Implementation here
    return {"forecast": f"{days} day forecast for {city}"}

if __name__ == "__main__":
    mcp.run(port=3000, transport="sse")
```

### 2. Create Dockerfile

Create `servers/weather/Dockerfile`:

```dockerfile
FROM python:3.11-slim
WORKDIR /app
RUN pip install fastmcp requests
COPY server.py .
CMD ["python", "server.py"]
```

### 3. Add to Docker Compose

Edit `docker-compose-fastmcp.yml`:

```yaml
services:
  # ... existing services ...
  
  mcp-weather:
    build: ./servers/weather
    container_name: mcp-weather
    restart: always
    ports:
      - "127.0.0.1:3002:3000"  # New port!
    environment:
      - WEATHER_API_KEY=${WEATHER_API_KEY}
```

### 4. Deploy

```bash
docker-compose -f docker-compose-fastmcp.yml up -d --build mcp-weather
```

### 5. Add to Claude Desktop

Update SSH tunnel on Mac:
```bash
ssh -L 3001:localhost:3001 -L 3002:localhost:3002 root@134.199.159.190
```

Add to `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "weather": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-sse-client",
        "http://localhost:3002/sse"
      ]
    }
  }
}
```

## MCP Server Templates

### Database Query Server

```python
from fastmcp import FastMCP
import psycopg2
from typing import List, Dict

mcp = FastMCP("database")

@mcp.tool()
def query(sql: str, params: List = None) -> List[Dict]:
    """Execute SQL query safely"""
    conn = psycopg2.connect(os.environ['DATABASE_URL'])
    cur = conn.cursor()
    cur.execute(sql, params or [])
    
    # Convert to dict
    columns = [desc[0] for desc in cur.description]
    results = [dict(zip(columns, row)) for row in cur.fetchall()]
    
    conn.close()
    return results

@mcp.tool()
def list_tables() -> List[str]:
    """List all database tables"""
    result = query(
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
    )
    return [r['table_name'] for r in result]
```

### AI Tool Server (OpenAI/Anthropic)

```python
from fastmcp import FastMCP
import openai

mcp = FastMCP("ai-tools")

@mcp.tool()
def generate_code(prompt: str, language: str = "python") -> str:
    """Generate code using AI"""
    client = openai.OpenAI(api_key=os.environ['OPENAI_API_KEY'])
    
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": f"Generate {language} code"},
            {"role": "user", "content": prompt}
        ]
    )
    
    return response.choices[0].message.content

@mcp.tool()
def analyze_image(image_path: str, question: str) -> str:
    """Analyze image with AI vision"""
    # Implementation here
    pass
```

### Web Scraper Server

```python
from fastmcp import FastMCP
from bs4 import BeautifulSoup
import requests

mcp = FastMCP("scraper")

@mcp.tool()
def scrape_url(url: str, selector: str = None) -> str:
    """Scrape content from URL"""
    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')
    
    if selector:
        elements = soup.select(selector)
        return [elem.text for elem in elements]
    
    return soup.get_text()

@mcp.tool()
def extract_links(url: str) -> List[str]:
    """Extract all links from page"""
    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')
    return [a['href'] for a in soup.find_all('a', href=True)]
```

## Best Practices

### 1. Environment Variables

Use `.env` files for secrets:

```bash
# servers/weather/.env
WEATHER_API_KEY=your-key-here
```

Load in Docker Compose:
```yaml
env_file:
  - ./servers/weather/.env
```

### 2. Error Handling

```python
@mcp.tool()
def risky_operation(param: str) -> dict:
    """Operation that might fail"""
    try:
        # Your code here
        result = do_something(param)
        return {"success": True, "data": result}
    except Exception as e:
        return {"success": False, "error": str(e)}
```

### 3. Type Hints

Always use type hints for better Claude understanding:

```python
from typing import List, Dict, Optional

@mcp.tool()
def complex_tool(
    required: str,
    optional: Optional[str] = None,
    count: int = 10
) -> Dict[str, List[str]]:
    """Tool with proper typing"""
    pass
```

### 4. Logging

```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@mcp.tool()
def logged_operation(param: str) -> str:
    logger.info(f"Processing: {param}")
    result = process(param)
    logger.info(f"Result: {result}")
    return result
```

## Testing Your MCP Server

### Local Testing

```python
# servers/weather/test.py
from server import mcp

# Test directly
result = mcp.tools["get_weather"]("London")
print(result)
```

### Docker Testing

```bash
# Build and run
docker build -t mcp-weather ./servers/weather
docker run -p 3002:3000 mcp-weather

# Test endpoint
curl http://localhost:3002/sse
```

### Integration Testing

```bash
# Full stack test
docker-compose -f docker-compose-fastmcp.yml up -d
./scripts/test-fastmcp.sh
```

## Common Patterns

### 1. File Processing
```python
@mcp.tool()
def process_csv(path: str) -> dict:
    import pandas as pd
    df = pd.read_csv(f"/data/{path}")
    return {
        "rows": len(df),
        "columns": list(df.columns),
        "summary": df.describe().to_dict()
    }
```

### 2. External API Calls
```python
@mcp.tool()
def call_api(endpoint: str, method: str = "GET", data: dict = None) -> dict:
    response = requests.request(
        method=method,
        url=f"https://api.service.com/{endpoint}",
        json=data,
        headers={"Authorization": f"Bearer {os.environ['API_KEY']}"}
    )
    return response.json()
```

### 3. Background Tasks
```python
import asyncio
from concurrent.futures import ThreadPoolExecutor

executor = ThreadPoolExecutor(max_workers=4)

@mcp.tool()
def async_task(task_id: str) -> str:
    """Start background task"""
    executor.submit(long_running_task, task_id)
    return f"Task {task_id} started"
```

## Debugging

### View Logs
```bash
docker logs mcp-weather -f
```

### Interactive Shell
```bash
docker exec -it mcp-weather python
>>> from server import mcp
>>> mcp.tools
```

### Test from Claude
```
"Use the weather tool to get weather for London"
```

## Port Assignment

Keep track of your ports:

| Service | Port | Description |
|---------|------|-------------|
| filesystem | 3001 | File operations |
| weather | 3002 | Weather data |
| database | 3003 | SQL queries |
| ai-tools | 3004 | AI operations |
| scraper | 3005 | Web scraping |

## Troubleshooting

### Server won't start
- Check logs: `docker logs mcp-weather`
- Verify port not in use: `lsof -i :3002`
- Check Dockerfile syntax

### Claude can't connect
- Verify SSH tunnel is running
- Check port mapping in docker-compose
- Restart Claude Desktop after config changes

### Tools not showing
- Verify FastMCP decorators are correct
- Check server is running: `docker ps`
- Test SSE endpoint: `curl http://localhost:3002/sse`

## Next Steps

1. Start with simple tools (read/write operations)
2. Add error handling and logging
3. Implement more complex integrations
4. Share your MCP servers with the community!
