#!/usr/bin/env python3
"""
Lightweight Google Docs downloader using browser cookies.
No Google API dependencies required!
"""

import re
import sys
from pathlib import Path
import requests

try:
    import browser_cookie3
except ImportError:
    print("❌ Error: browser_cookie3 not installed")
    print("Install with: pip install browser-cookie3 requests")
    sys.exit(1)

# Configuration
OUTPUT_DIR = Path('downloaded_docs')
EXPORT_FORMAT = 'markdown'  # Options: markdown, pdf, docx, txt, html

# Export URL templates
EXPORT_URLS = {
    'markdown': 'https://docs.google.com/feeds/download/documents/export/Export?exportFormat=markdown&id={doc_id}',
    'pdf': 'https://docs.google.com/document/d/{doc_id}/export?format=pdf',
    'docx': 'https://docs.google.com/document/d/{doc_id}/export?format=docx',
    'txt': 'https://docs.google.com/document/d/{doc_id}/export?format=txt',
    'html': 'https://docs.google.com/document/d/{doc_id}/export?format=html',
}

def extract_doc_id(url):
    """Extract document ID from Google Docs URL"""
    match = re.search(r'/d/([a-zA-Z0-9-_]+)', url)
    return match.group(1) if match else None

def get_browser_cookies():
    """Get Google cookies from browser"""
    print("🍪 Loading cookies from browser...")
    
    try:
        # Try Chrome first
        cj = browser_cookie3.chrome(domain_name='.google.com')
        print("✅ Loaded cookies from Chrome")
        return cj
    except:
        pass
    
    try:
        # Try Firefox
        cj = browser_cookie3.firefox(domain_name='.google.com')
        print("✅ Loaded cookies from Firefox")
        return cj
    except:
        pass
    
    try:
        # Try Safari (macOS)
        cj = browser_cookie3.safari(domain_name='.google.com')
        print("✅ Loaded cookies from Safari")
        return cj
    except:
        pass
    
    print("❌ Error: Could not load cookies from any browser")
    print("Make sure you're logged into Google Docs in Chrome, Firefox, or Safari")
    sys.exit(1)

def download_document(doc_id, cookies, format='markdown'):
    """Download a Google Doc in specified format"""
    url_template = EXPORT_URLS.get(format, EXPORT_URLS['markdown'])
    url = url_template.format(doc_id=doc_id)
    
    try:
        response = requests.get(url, cookies=cookies, timeout=30)
        response.raise_for_status()
        
        # Get filename from Content-Disposition header if available
        filename = None
        if 'Content-Disposition' in response.headers:
            cd = response.headers['Content-Disposition']
            match = re.search(r'filename="(.+)"', cd)
            if match:
                filename = match.group(1)
        
        # Fallback to doc_id if no filename
        if not filename:
            ext = format if format != 'markdown' else 'md'
            filename = f"document_{doc_id[:8]}.{ext}"
        
        # Clean filename
        filename = re.sub(r'[^\w\s\-\.]', '_', filename)
        
        return response.content, filename
        
    except requests.exceptions.RequestException as e:
        raise Exception(f"Download failed: {e}")

def main():
    """Main function"""
    # Create output directory
    OUTPUT_DIR.mkdir(exist_ok=True)
    
    # Read URLs from file
    try:
        with open('google-docs-urls.txt', 'r') as f:
            urls = [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        print("❌ Error: google-docs-urls.txt not found")
        sys.exit(1)
    
    if not urls:
        print("❌ Error: No URLs found in google-docs-urls.txt")
        sys.exit(1)
    
    # Get browser cookies
    cookies = get_browser_cookies()
    
    # Process documents
    total = len(urls)
    successful = 0
    failed = []
    processed_ids = set()
    
    print(f"\n📄 Found {total} URLs to process")
    print(f"📦 Export format: {EXPORT_FORMAT}\n")
    
    for i, url in enumerate(urls, 1):
        doc_id = extract_doc_id(url)
        
        if not doc_id:
            print(f"[{i}/{total}] ⚠️  Invalid URL: {url}")
            failed.append((url, "Invalid URL format"))
            continue
        
        if doc_id in processed_ids:
            print(f"[{i}/{total}] ⏭️  Skipping duplicate: {doc_id}")
            continue
        
        processed_ids.add(doc_id)
        
        try:
            print(f"[{i}/{total}] 📥 Downloading: {doc_id[:8]}...", end='', flush=True)
            
            content, filename = download_document(doc_id, cookies, EXPORT_FORMAT)
            
            # Save file
            output_path = OUTPUT_DIR / filename
            
            # Handle duplicates by adding number
            if output_path.exists():
                base = output_path.stem
                ext = output_path.suffix
                counter = 1
                while output_path.exists():
                    output_path = OUTPUT_DIR / f"{base}_{counter}{ext}"
                    counter += 1
            
            with open(output_path, 'wb') as f:
                f.write(content)
            
            successful += 1
            print(f" ✅ Saved as: {output_path.name}")
            
        except Exception as e:
            print(f" ❌ Failed")
            print(f"        Error: {e}")
            failed.append((url, str(e)))
    
    # Summary
    print(f"\n{'='*50}")
    print(f"📊 Summary:")
    print(f"   ✅ Successfully downloaded: {successful}")
    print(f"   ❌ Failed: {len(failed)}")
    print(f"   ⏭️  Skipped duplicates: {len(urls) - len(processed_ids) - len(failed)}")
    
    if failed:
        print(f"\n❌ Failed downloads:")
        for url, error in failed:
            print(f"   - {url}")
            print(f"     Error: {error}")
    
    print(f"\n📁 All documents saved to: {OUTPUT_DIR.absolute()}")
    
    # Help message for authentication issues
    if failed and any("403" in str(error) for _, error in failed):
        print("\n💡 Tip: If you're getting 403 errors:")
        print("   1. Make sure you're logged into Google Docs in your browser")
        print("   2. Try opening one of the documents manually first")
        print("   3. Check that the documents are shared with your account")

if __name__ == '__main__':
    main()