import os
import re
import sys
from pathlib import Path
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
import io

# Setup credentials
cred_path = os.environ.get('GOOGLE_CREDS_PATH', 'credentials.json')
if not os.path.exists(cred_path):
    print(f"❌ Error: Credentials file not found at '{cred_path}'")
    print("Set GOOGLE_CREDS_PATH environment variable or place credentials.json in current directory")
    sys.exit(1)

try:
    credentials = service_account.Credentials.from_service_account_file(
        cred_path,
        scopes=['https://www.googleapis.com/auth/drive.readonly']
    )
    service = build('drive', 'v3', credentials=credentials)
except Exception as e:
    print(f"❌ Error loading credentials: {e}")
    sys.exit(1)

# Create output directory
output_dir = Path('downloaded_docs')
output_dir.mkdir(exist_ok=True)

def extract_doc_id(url):
    """Extract document ID from Google Docs URL"""
    match = re.search(r'/d/([a-zA-Z0-9-_]+)', url)
    return match.group(1) if match else None

def download_as_markdown(doc_id, output_path):
    """Download Google Doc as markdown"""
    request = service.files().export_media(
        fileId=doc_id,
        mimeType='text/markdown'
    )
    
    fh = io.BytesIO()
    downloader = MediaIoBaseDownload(fh, request)
    
    done = False
    while not done:
        status, done = downloader.next_chunk()
    
    # Save to file
    with open(output_path, 'wb') as f:
        f.write(fh.getvalue())

# Read URLs from file
try:
    with open('google-docs-urls.txt', 'r') as f:
        urls = [line.strip() for line in f if line.strip()]
except FileNotFoundError:
    print("❌ Error: google-docs-urls.txt not found")
    sys.exit(1)

# Process documents
total = len(urls)
successful = 0
failed = []
processed_ids = set()

print(f"📄 Found {total} URLs to process\n")

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
        # Get document metadata
        file = service.files().get(fileId=doc_id).execute()
        filename = file['name'].replace('/', '-').replace('\\', '-')
        
        # Create filename with ID to avoid conflicts
        output_path = output_dir / f"{filename}_{doc_id[:8]}.md"
        
        print(f"[{i}/{total}] 📥 Downloading: {filename}")
        download_as_markdown(doc_id, output_path)
        
        successful += 1
        print(f"        ✅ Saved to: {output_path}")
        
    except Exception as e:
        error_msg = str(e)
        print(f"        ❌ Failed: {error_msg}")
        failed.append((url, error_msg))

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

print(f"\n📁 All documents saved to: {output_dir.absolute()}")