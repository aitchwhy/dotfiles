# Cline MCP Configuration

This directory contains configuration files for Cline MCP (Model Context Protocol) servers.

## Installed MCP Servers

### Time MCP Server

- **Server Name**: `github.com/modelcontextprotocol/servers/tree/main/src/time`
- **Installation Method**: Using `uvx` (uv execute)
- **Command**: `uvx mcp-server-time`
- **Source**: [GitHub Repository](https://github.com/modelcontextprotocol/servers/tree/main/src/time)

#### Available Tools

1. `get_current_time` - Get current time in a specific timezone
   - Required arguments:
     - `timezone` (string): IANA timezone name (e.g., 'America/New_York', 'Europe/London')

2. `convert_time` - Convert time between timezones
   - Required arguments:
     - `source_timezone` (string): Source IANA timezone name
     - `time` (string): Time in 24-hour format (HH:MM)
     - `target_timezone` (string): Target IANA timezone name

## Usage Examples

### Get Current Time

```json
{
  "name": "get_current_time",
  "arguments": {
    "timezone": "Europe/Warsaw"
  }
}
```

### Convert Time Between Timezones

```json
{
  "name": "convert_time",
  "arguments": {
    "source_timezone": "America/New_York",
    "time": "16:30",
    "target_timezone": "Asia/Tokyo"
  }
}
```

## Configuration

The MCP server configuration is stored in `cline_mcp_settings.json` in this directory. The Cursor settings file is configured to use this custom path for MCP settings.
