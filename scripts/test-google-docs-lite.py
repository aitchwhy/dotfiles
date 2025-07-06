#!/usr/bin/env python3
"""Test script for google-docs-lite.py"""

import re
from pathlib import Path

# Test URL extraction
test_urls = [
    "https://docs.google.com/document/d/1wzgj2zRUjSaBsolj0669bZU_hTIV5ny5Y4Dq2DkEiao/edit?tab=t.0",
    "https://docs.google.com/document/d/1ls-MJJY6zVt7jkGkTx23hMyE4iKZXlXmknOqcTnNRI4/edit",
    "invalid-url",
    ""
]

def extract_doc_id(url):
    """Extract document ID from Google Docs URL"""
    match = re.search(r'/d/([a-zA-Z0-9-_]+)', url)
    return match.group(1) if match else None

print("Testing URL extraction:")
print("-" * 50)

for url in test_urls:
    doc_id = extract_doc_id(url)
    if doc_id:
        print(f"✅ Valid URL: {url[:50]}...")
        print(f"   Doc ID: {doc_id}")
    else:
        print(f"❌ Invalid URL: {url}")
    print()

# Test export URL generation
print("\nTesting export URL generation:")
print("-" * 50)

EXPORT_URLS = {
    'markdown': 'https://docs.google.com/feeds/download/documents/export/Export?exportFormat=markdown&id={doc_id}',
    'pdf': 'https://docs.google.com/document/d/{doc_id}/export?format=pdf',
    'docx': 'https://docs.google.com/document/d/{doc_id}/export?format=docx',
}

test_doc_id = "1wzgj2zRUjSaBsolj0669bZU_hTIV5ny5Y4Dq2DkEiao"

for format_name, url_template in EXPORT_URLS.items():
    export_url = url_template.format(doc_id=test_doc_id)
    print(f"{format_name.upper()}: {export_url}")

print("\n✅ All tests completed!")
print("\nTo download documents, run:")
print("  python google-docs-lite.py")
print("\nMake sure you have browser-cookie3 installed:")
print("  pip install browser-cookie3 requests")