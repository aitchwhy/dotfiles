# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Google Docs automation scripts directory that downloads and converts Google Docs to markdown format. It's part of a larger dotfiles repository and uses Python with the Google Drive API.

## Development Commands

### Setup and Dependencies
```bash
# Install dependencies using uv (modern Python package manager)
uv sync

# Or install manually
uv pip install -e .
```

### Running Scripts
```bash
# Set credentials path (or place credentials.json in current directory)
export GOOGLE_CREDS_PATH=/path/to/your/credentials.json

# Run the main Google Docs downloader
uv run python google-docs.py

# Run the simple entry point
uv run python main.py
```

## Architecture and Key Components

### Core Scripts
- **google-docs.py**: Main automation script that:
  - Authenticates with Google Drive API using service account credentials
  - Extracts document IDs from Google Docs URLs in `google-docs-urls.txt`
  - Downloads documents and converts them to markdown format
  - Saves files with sanitized names (replaces slashes with dashes)

### Configuration Requirements
Before running google-docs.py:
1. Obtain Google Cloud service account credentials with Drive API access
2. Either:
   - Set environment variable: `export GOOGLE_CREDS_PATH=/path/to/credentials.json`
   - Or place `credentials.json` in the scripts directory
3. Ensure google-docs-urls.txt contains valid Google Docs URLs

### Project Structure
- Uses modern Python packaging with pyproject.toml
- Manages dependencies with uv package manager
- Requires Python 3.9 or higher
- Primary dependency: google>=3.0.0 (Google API client libraries)

## Important Notes
- The google-docs-urls.txt file contains 22 Google Docs URLs to process
- Downloaded markdown files are saved in the `downloaded_docs/` directory
- Files are named with document title and partial ID to avoid conflicts
- The script handles duplicates, tracks progress, and provides error reporting
- Service account needs 'https://www.googleapis.com/auth/drive.readonly' scope
- Script continues processing even if individual downloads fail