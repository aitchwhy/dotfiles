# Lightweight Google Docs Download Methods

This document describes lightweight alternatives to download Google Docs without heavy dependencies.

## Overview

Instead of using the full Google API client libraries, we now have two lightweight options:

1. **Python with Browser Cookies** (`google-docs-lite.py`)
2. **Pure Shell Script** (`google-docs-curl.sh`)

## Method 1: Python with Browser Cookies

### Requirements
- Python 3.x
- Two small packages: `browser-cookie3` and `requests`

### Installation
```bash
pip install browser-cookie3 requests
```

### Usage
```bash
python google-docs-lite.py
```

### Features
- Automatically extracts cookies from your browser (Chrome, Firefox, Safari)
- No Google API credentials needed
- Uses your existing Google login
- Supports multiple export formats (markdown, pdf, docx, txt, html)

### How it works
1. Reads Google Docs URLs from `google-docs-urls.txt`
2. Extracts cookies from your browser
3. Downloads documents using Google's export URLs
4. Saves to `downloaded_docs/` directory

## Method 2: Pure Shell Script

### Requirements
- bash
- curl (pre-installed on most systems)
- A cookies.txt file

### Setup
1. Install a browser extension like "cookies.txt" for Chrome/Firefox
2. Log into Google Docs
3. Export cookies for google.com domain
4. Save as `~/.google-cookies.txt`

### Usage
```bash
./google-docs-curl.sh
```

### Configuration
Edit the script to change:
- `FORMAT`: Export format (markdown, pdf, docx, txt, html)
- `OUTPUT_DIR`: Where to save files
- `COOKIE_FILE`: Path to your cookies file

## Export URL Formats

Both methods use Google's direct export URLs:

### Markdown
```
https://docs.google.com/feeds/download/documents/export/Export?exportFormat=markdown&id={DOC_ID}
```

### PDF
```
https://docs.google.com/document/d/{DOC_ID}/export?format=pdf
```

### Other Formats
- DOCX: `format=docx`
- TXT: `format=txt`
- HTML: `format=html`

## Comparison

| Feature | google-docs-lite.py | google-docs-curl.sh | Original (API) |
|---------|-------------------|-------------------|----------------|
| Dependencies | 2 Python packages | None | 5+ Google packages |
| Setup | pip install | Export cookies | Service account |
| Authentication | Browser cookies | Cookie file | API credentials |
| Cross-platform | Yes | Unix/Mac | Yes |
| Error handling | Good | Basic | Excellent |

## Troubleshooting

### Access Denied (403 errors)
1. Make sure you're logged into Google Docs in your browser
2. Try opening one document manually first
3. Check that documents are shared with your account

### Cookie Issues
- **Python version**: Restart browser and try again
- **Shell version**: Re-export cookies from browser

### Format Issues
- Markdown export preserves most formatting
- Images are embedded as base64 (may be large)
- Complex formatting may be lost

## When to Use Each Method

### Use `google-docs-lite.py` when:
- You want automatic cookie extraction
- You need better error handling
- You're on Windows or need cross-platform support

### Use `google-docs-curl.sh` when:
- You want zero Python dependencies
- You're comfortable with shell scripts
- You need maximum simplicity

### Use the original API version when:
- You need programmatic access without browser
- You're downloading many documents regularly
- You need advanced features (metadata, permissions, etc.)

## Security Notes

- Both lightweight methods require you to be logged into Google
- Cookies expire; you may need to refresh them periodically
- These methods only work for documents you have access to
- No credentials are stored in the scripts