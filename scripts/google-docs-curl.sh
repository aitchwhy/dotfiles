#!/bin/bash
# Lightweight Google Docs downloader using curl
# No Python dependencies required!

# Configuration
OUTPUT_DIR="downloaded_docs"
FORMAT="markdown"  # Options: markdown, pdf, docx, txt, html
COOKIE_FILE="$HOME/.google-cookies.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to extract document ID from URL
extract_doc_id() {
    echo "$1" | grep -oE '/d/[a-zA-Z0-9_-]+' | cut -d'/' -f3
}

# Function to get export URL based on format
get_export_url() {
    local doc_id=$1
    local format=$2
    
    case $format in
        markdown)
            echo "https://docs.google.com/feeds/download/documents/export/Export?exportFormat=markdown&id=$doc_id"
            ;;
        pdf)
            echo "https://docs.google.com/document/d/$doc_id/export?format=pdf"
            ;;
        docx)
            echo "https://docs.google.com/document/d/$doc_id/export?format=docx"
            ;;
        txt)
            echo "https://docs.google.com/document/d/$doc_id/export?format=txt"
            ;;
        html)
            echo "https://docs.google.com/document/d/$doc_id/export?format=html"
            ;;
        *)
            echo "https://docs.google.com/feeds/download/documents/export/Export?exportFormat=markdown&id=$doc_id"
            ;;
    esac
}

# Function to get file extension based on format
get_extension() {
    case $1 in
        markdown) echo "md" ;;
        *) echo "$1" ;;
    esac
}

# Check if cookie file exists
if [ ! -f "$COOKIE_FILE" ]; then
    echo -e "${YELLOW}⚠️  Cookie file not found at: $COOKIE_FILE${NC}"
    echo "To create a cookie file:"
    echo "1. Install a browser extension like 'cookies.txt' for Chrome/Firefox"
    echo "2. Log into Google Docs"
    echo "3. Export cookies for google.com domain"
    echo "4. Save as $COOKIE_FILE"
    echo ""
    echo "Alternatively, you can use the Python version: python google-docs-lite.py"
    exit 1
fi

# Check if google-docs-urls.txt exists
if [ ! -f "google-docs-urls.txt" ]; then
    echo -e "${RED}❌ Error: google-docs-urls.txt not found${NC}"
    exit 1
fi

# Read URLs from file
mapfile -t urls < <(grep -v '^$' google-docs-urls.txt)
total=${#urls[@]}

if [ $total -eq 0 ]; then
    echo -e "${RED}❌ Error: No URLs found in google-docs-urls.txt${NC}"
    exit 1
fi

echo -e "📄 Found ${GREEN}$total${NC} URLs to process"
echo -e "📦 Export format: ${GREEN}$FORMAT${NC}"
echo ""

# Process each URL
successful=0
failed=0
processed_ids=()

for i in "${!urls[@]}"; do
    url="${urls[$i]}"
    progress=$((i + 1))
    
    # Extract document ID
    doc_id=$(extract_doc_id "$url")
    
    if [ -z "$doc_id" ]; then
        echo -e "[$progress/$total] ${YELLOW}⚠️  Invalid URL: $url${NC}"
        ((failed++))
        continue
    fi
    
    # Check for duplicates
    if [[ " ${processed_ids[@]} " =~ " $doc_id " ]]; then
        echo -e "[$progress/$total] ${YELLOW}⏭️  Skipping duplicate: $doc_id${NC}"
        continue
    fi
    
    processed_ids+=("$doc_id")
    
    # Get export URL and filename
    export_url=$(get_export_url "$doc_id" "$FORMAT")
    ext=$(get_extension "$FORMAT")
    filename="document_${doc_id:0:8}.${ext}"
    output_path="$OUTPUT_DIR/$filename"
    
    # Download the document
    echo -n "[$progress/$total] 📥 Downloading: ${doc_id:0:8}... "
    
    if curl -s -b "$COOKIE_FILE" -L "$export_url" -o "$output_path" --fail; then
        echo -e "${GREEN}✅ Saved as: $filename${NC}"
        ((successful++))
    else
        echo -e "${RED}❌ Failed${NC}"
        ((failed++))
        rm -f "$output_path"  # Remove empty file
    fi
done

# Summary
echo ""
echo "=================================================="
echo "📊 Summary:"
echo -e "   ✅ Successfully downloaded: ${GREEN}$successful${NC}"
echo -e "   ❌ Failed: ${RED}$failed${NC}"
echo -e "   ⏭️  Skipped duplicates: $((total - ${#processed_ids[@]} - failed))"
echo ""
echo "📁 All documents saved to: $(pwd)/$OUTPUT_DIR"

if [ $failed -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}💡 Tip: If downloads failed:${NC}"
    echo "   1. Make sure your cookie file is up to date"
    echo "   2. Check that you have access to the documents"
    echo "   3. Try the Python version for better cookie handling"
fi