# How to install:
# Put this into your claude_desktop_config.json (either at ~/Library/Application Support/Claude on macOS or C:\Users\NAME\AppData\Roaming\Claude on Windows):
#
#   "mcpServers": {
#     "mcp-installer": {
#       "command": "npx",
#       "args": [
#         "@anaisbetts/mcp-installer"
#       ]
#     }
#   }
#
# Example prompts
# 
# Hey Claude, install the MCP server named mcp-server-fetch
# Hey Claude, install the @modelcontextprotocol/server-filesystem package as an MCP server. Use ['/Users/anibetts/Desktop'] for the arguments
# Hi Claude, please install the MCP server at /Users/anibetts/code/mcp-youtube, I'm too lazy to do it myself.
# Install the server @modelcontextprotocol/server-github. Set the environment variable GITHUB_PERSONAL_ACCESS_TOKEN to '1234567890'

#  Cloudflare (MCP server for interacting with Cloudflare API)
npx @michaellatman/mcp-get@latest install @cloudflare/mcp-server-cloudflare

# YT transcript (This is an MCP server that allows you to directly download transcripts of YouTube videos.)
npx @michaellatman/mcp-get@latest install @kimtaeyoon83/mcp-server-youtube-transcript

# Search1API 
npx @michaellatman/mcp-get@latest install @fatwang2/search1api-mcp
# npx @michaellatman/mcp-get@latest install @modelcontextprotocol/search1api-mcp


# install everything server - https://mcp-get.com/packages/%40modelcontextprotocol%2Fserver-everything
# MCP server that exercises all the features of the MCP protocol
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-everything

# MCP server for filesystem access
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-filesystem

# MCP server for enabling memory for Claude through a knowledge graph
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-memory

# puppeteer (MCP server for interacting with Puppeteer)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-puppeteer

# fetch (MCP server for interacting with Fetch API)
npx @michaellatman/mcp-get@latest install mcp-server-fetch

# github (MCP server for interacting with GitHub API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-github

# brave (MCP server for interacting with Brave Search API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-brave-search

# sequential thinking (MCP server for sequential thinking and problem solving)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-sequential-thinking

# Obsidian (MCP server for interacting with Obsidian API)
npx @smithery/cli install mcp-obsidian --client claude
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-obsidian

# server aws kb retrieval (MCP server for interacting with AWS API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-aws-kb-retrieval

# sentry (MCP server for interacting with Sentry API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-sentry

# google maps (MCP server for interacting with Google Maps API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-google-maps

# google drive (MCP server for interacting with Google Drive API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-google-drive

# google news (MCP server for interacting with Google News API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-google-news

# mcp-server (MCP server for interacting with MCP API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-mcp


# server llm txt retrieval (MCP server for interacting with LLM API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-llm-txt-retrieval

# postgres (MCP server for interacting with PostgreSQL API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-postgres

# macos (MCP server for interacting with macOS API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-macos

# sqlite (MCP server for interacting with SQLite API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-sqlite

# curl (MCP server for interacting with Curl API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-curl


# playwright (MCP server for interacting with Playwright API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-playwright

# mcp-server-commands (MCP server for interacting with MCP API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-commands

# kubernetes (MCP server for interacting with Kubernetes API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-kubernetes

# server slack (MCP server for interacting with Slack API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-slack

# twitter (MCP server for interacting with Twitter API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-twitter

# everart (MCP server for interacting with Everart API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-everart

# airtable (MCP server for interacting with Airtable API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-airtable

# Git (MCP server for interacting with Git API)
npx @michaellatman/mcp-get@latest install mcp-server-git

# mcp-shell (MCP server for interacting with MCP Shell API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-mcp-shell

# docker (MCP server for interacting with Docker API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-docker

# solver (MCP server for interacting with Solver API)
npx @michaellatman/mcp-get@latest install @modelcontextprotocol/server-solver


################
# Opentools version
################

# https://opentools.com/registry/cloudflare
npx opentools i cloudflare

# https://opentools.com/registry/neon
npx opentools i neon

# This setup allows AI models to get real-time web information in a safe and controlled way.
npx opentools i exa

# This server enables LLMs to interact with web pages, perform actions, extract data, and observe possible actions in a real browser environment
npx opentools i stagehand

# Automate browser interactions in the cloud (e.g. web navigation, data extraction, form filling, and more)
npx opentools i browserbase


npx opentools i cloudflare-workers-mcp

# A proxy server that converts OpenAPI v3.1 specifications into Claude tools, enabling natural language interaction with APIs through Claude Desktop.
npx opentools i snaggle-ai-openapi-mcp-server

# A server that allows LLMs like Claude to execute shell commands and scripts, returning output and errors.
npx opentools i g0t4-mcp-server-commands

# huggingface (MCP server for interacting with Huggingface Spaces API)
npx opentools i mcp-hfspace

# An MCP server implementation that integrates Claude with Todoist, enabling natural language task management for creating, updating, completing, and deleting tasks.
npx opentools i abhiz123-todoist-mcp-server


# airtable
npx opentools i domdomegg-airtable-mcp-server

# flight info
npx opentools i ravinahp-flights-mcp

# An MCP server that provides integration between Neo4j graph database and Claude Desktop, enabling graph database operations through natural language interactions.
npx opentools i da-okazaki-mcp-neo4j-server

# cline personas
npx opentools i bradfair-mcp-cline-personas

# memgpt
npx opentools i vic563-memgpt-mcp-server

# Docker - A Model Context Protocol (MCP) server for Docker operations, enabling container and compose stack management through Claude AI.
npx opentools i quantgeekdev-docker-mcp

# QDrant  - A Model Context Protocol server for storing and retrieving memories using the Qdrant vector search engine, acting as a semantic memory layer.
npx opentools i qdrant-mcp-server-qdrant


# Stability AI
npx opentools i tadasant-mcp-server-stability-ai

# macos - A Model Context Protocol server that provides macOS-specific system information and operations, including CPU, memory, disk, network details, and native macOS notifications.
npx opentools i mcp-get-community-servers-server-macos

# everything search
npx opentools i mamertofabian-mcp-everything-search


# google workspace/suite
npx opentools i markuspfundstein-mcp-gsuite

# A beginner-friendly Model Context Protocol (MCP) server that provides explanations of MCP concepts, interactive examples, and a directory of available MCP servers.
npx opentools i qpd-v-mcp-guide

# A Model Context Protocol (MCP) server that extracts and serves context from llm.txt files, enabling AI models to understand file structure, dependencies, and code relationships in development environments.
npx opentools i mcp-get-community-servers-server-llm-txt


# mcp-pandoc - A Model Context Protocol (MCP) server that provides a simple interface for converting Markdown, HTML, and other common document formats to PDF, DOCX, and more.

uv tool install mcp-pandoc








##############
# Smithery.ai
##############

# AWS
npx -y @smithery/cli install mcp-server-aws --client claude
