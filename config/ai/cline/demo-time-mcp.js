#!/usr/bin/env node

/**
 * MCP Time Server Demo Script
 *
 * This script demonstrates how to use the Time MCP Server tools
 * to get current time in different timezones and convert time between timezones.
 *
 * Usage:
 *   node demo-time-mcp.js
 */

// Sample request for get_current_time
const getCurrentTimeRequest = {
  name: "get_current_time",
  arguments: {
    timezone: "America/New_York",
  },
};

// Sample request for convert_time
const convertTimeRequest = {
  name: "convert_time",
  arguments: {
    source_timezone: "America/New_York",
    time: "15:30",
    target_timezone: "Asia/Tokyo",
  },
};

console.log("Time MCP Server Demo");
console.log("====================");
console.log("\nTo use these tools in Cline, you can ask questions like:");
console.log('- "What time is it now?"');
console.log('- "What time is it in Tokyo?"');
console.log('- "When it\'s 4 PM in New York, what time is it in London?"');
console.log('- "Convert 9:30 AM Tokyo time to New York time"');

console.log("\nSample MCP Tool Requests:");
console.log("\n1. Get Current Time Request:");
console.log(JSON.stringify(getCurrentTimeRequest, null, 2));

console.log("\n2. Convert Time Request:");
console.log(JSON.stringify(convertTimeRequest, null, 2));

console.log("\nMCP Server Configuration:");
console.log(
  "- Server Name: github.com/modelcontextprotocol/servers/tree/main/src/time",
);
console.log("- Command: uvx mcp-server-time");
console.log(
  "- Configuration File: ~/dotfiles/config/ai/cline/cline_mcp_settings.json",
);

console.log(
  "\nNote: To use these tools in Cline, you need to restart Cline or reload the window after configuring the MCP server.",
);
