# Scripts Directory

This directory contains automation scripts for various tasks, including Google Docs download automation and iPhone stopwatch screenshot OCR processing.

## =Ú Table of Contents

- [Google Docs Download Tools](#google-docs-download-tools)
  - [Lightweight Methods (Recommended)](#lightweight-methods-recommended)
  - [API-Based Method](#api-based-method)
  - [Comparison](#comparison)
- [Stopwatch OCR Tool](#stopwatch-ocr-tool)
- [Setup](#setup)
- [Troubleshooting](#troubleshooting)

## Google Docs Download Tools

Download Google Docs in various formats (Markdown, PDF, DOCX, etc.) using three different approaches.

### =€ Lightweight Methods (Recommended)

#### 1. Browser Cookie Method (`google-docs-lite.py`)

The easiest method - uses your existing browser session.

**Features:**
-  No Google API setup required
-  Automatically extracts cookies from Chrome/Firefox/Safari
-  Minimal dependencies (just 2 Python packages)
-  Supports multiple export formats

**Quick Start:**
```bash
# Install dependencies
pip install browser-cookie3 requests

# Add your Google Docs URLs to the file
echo "https://docs.google.com/document/d/YOUR_DOC_ID/edit" >> google-docs-urls.txt

# Run the script
python google-docs-lite.py
```

**Supported Formats:**
- Markdown (.md)
- PDF (.pdf)
- Word (.docx)
- Plain Text (.txt)
- HTML (.html)

#### 2. Shell Script Method (`google-docs-curl.sh`)

Zero Python dependencies - uses only curl.

**Setup:**
1. Install a browser extension like "cookies.txt" 
2. Export cookies for google.com domain
3. Save as `~/.google-cookies.txt`

**Usage:**
```bash
# Make script executable
chmod +x google-docs-curl.sh

# Run the script
./google-docs-curl.sh
```

**Configuration:**
Edit the script to change:
- `FORMAT`: Export format (default: markdown)
- `OUTPUT_DIR`: Where to save files (default: downloaded_docs)
- `COOKIE_FILE`: Path to cookies file

### =æ API-Based Method

#### Original Google API Method (`google-docs.py`)

Uses official Google Drive API with service account authentication.

**When to Use:**
- Need programmatic access without browser
- Downloading many documents regularly  
- Require advanced features (metadata, permissions)
- Building automated pipelines

**Setup:**
1. Create a Google Cloud project
2. Enable Google Drive API
3. Create service account credentials
4. Download credentials as JSON

**Usage:**
```bash
# Set credentials path
export GOOGLE_CREDS_PATH=/path/to/credentials.json

# Or place credentials.json in current directory
cp /path/to/credentials.json .

# Run the script
python google-docs.py
```

### =Ê Comparison

| Feature | `google-docs-lite.py` | `google-docs-curl.sh` | `google-docs.py` (API) |
|---------|---------------------|---------------------|---------------------|
| **Dependencies** | 2 packages | None (curl only) | 5+ Google packages |
| **Setup Complexity** | P Easy | PP Moderate | PPP Complex |
| **Authentication** | Browser cookies | Cookie file | Service account |
| **Cross-platform** |  Yes | =6 Unix/Mac |  Yes |
| **Error Handling** |  Good | =6 Basic |  Excellent |
| **Batch Download** |  Yes |  Yes |  Yes |
| **Format Support** |  All |  All |  All |
| **Private Docs** |  Yes |  Yes |  Yes |
| **No Browser Needed** | L No | L No |  Yes |

## = Stopwatch OCR Tool

Extract timing data from iPhone stopwatch screenshots using OCR.

### Features
- Processes batches of stopwatch screenshots
- Extracts digital display readings (MM:SS.hh format)
- Detects handwritten yellow ink annotations
- Falls back to Apple Live Text JSON sidecars
- Outputs CSV with timestamps and readings
- Handles multiple readings per image

### Usage

```bash
# Install dependencies
pip install pillow pytesseract opencv-python numpy pytest

# Process screenshots
python main.py --src /path/to/screenshots --out stopwatch_data.csv
```

### Output Format

Creates a CSV with columns:
- `capture_ts`: Screenshot timestamp (UTC ISO-8601)
- `reading_raw`: Exact text found (e.g., "00:45.23" or "42")
- `reading_ms`: Converted to milliseconds

Also creates `extract_log.jsonl` with detailed OCR results.

## =à Setup

### Prerequisites

- Python 3.9+
- For OCR: Tesseract installed (`brew install tesseract` on macOS)
- For browser cookies: Active Google account login

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles/scripts

# Install Python dependencies (choose based on your needs)

# For Google Docs lightweight method only:
pip install browser-cookie3 requests

# For Google Docs API method:
pip install google-auth google-auth-httplib2 google-api-python-client

# For Stopwatch OCR:
pip install pillow pytesseract opencv-python numpy

# Or install everything:
pip install -r requirements.txt  # If you create one
```

### Configuration

1. **Google Docs URLs**: Add URLs to `google-docs-urls.txt`, one per line:
   ```
   https://docs.google.com/document/d/ABC123/edit
   https://docs.google.com/document/d/XYZ789/edit
   ```

2. **Output Directory**: Documents are saved to `downloaded_docs/` by default

3. **Export Format**: Change in script headers or via command line

## =' Troubleshooting

### Google Docs Download Issues

**403 Forbidden Errors:**
- Ensure you're logged into Google in your browser
- Try opening a document manually first
- Check document sharing permissions

**Cookie Issues:**
- Browser cookie method: Restart browser and try again
- Shell script: Re-export cookies using browser extension

**Missing Dependencies:**
```bash
# Check what's installed
pip list | grep -E "browser-cookie3|requests|google"

# Install missing packages
pip install browser-cookie3 requests
```

### OCR Issues

**No Text Found:**
- Ensure Tesseract is installed: `tesseract --version`
- Check image quality and resolution
- Try different PSM modes in the script

**Wrong Readings:**
- Adjust crop percentages in `extract_reading()`
- Tune yellow color detection HSV ranges
- Check if Live Text sidecar files exist

## =Ý File Descriptions

| File | Description |
|------|-------------|
| `google-docs-lite.py` | Lightweight Google Docs downloader using browser cookies |
| `google-docs-curl.sh` | Shell script alternative using curl |
| `google-docs.py` | Original API-based Google Docs downloader |
| `google-docs-urls.txt` | List of Google Docs URLs to download |
| `main.py` | Stopwatch OCR processing script |
| `test-google-docs-lite.py` | Test script for URL extraction |
| `GOOGLE_DOCS_LITE.md` | Detailed documentation for lightweight methods |
| `CLAUDE.md` | Instructions for AI assistants |

## > Contributing

1. Test your changes with the provided test scripts
2. Update documentation if adding new features
3. Follow existing code style and patterns

## =Ä License

Part of personal dotfiles - use as needed.

## = Related Tools

- [Tesseract OCR](https://github.com/tesseract-ocr/tesseract)
- [Google Drive API](https://developers.google.com/drive/api/v3/quickstart/python)
- [browser_cookie3](https://github.com/borisbabic/browser_cookie3)