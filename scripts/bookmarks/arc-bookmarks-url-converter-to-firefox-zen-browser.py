import re
from datetime import datetime
import time
import os
from urllib.parse import urlparse


def extract_urls_from_text(text):
    """Extract URLs from text content."""
    # This pattern matches URLs that start with http:// or https://
    url_pattern = r'https?://[^\s<>"]+|www\.[^\s<>"]+(?<![\.,])'
    return re.findall(url_pattern, text)


def get_title_from_url(url):
    """Generate a readable title from URL."""
    # Parse the URL and get the path
    parsed = urlparse(url)
    # Get the last meaningful part of the path
    path_parts = [p for p in parsed.path.split("/") if p]
    if path_parts:
        # Replace hyphens and underscores with spaces and capitalize
        title = path_parts[-1].replace("-", " ").replace("_", " ").title()
    else:
        # If no path, use the domain name
        title = parsed.netloc.split(".")[0].title()
    return title


def generate_firefox_bookmarks(urls, output_file="bookmarks.html"):
    """Generate Firefox-compatible bookmarks HTML file."""
    current_timestamp = int(time.time())

    # HTML template for Firefox bookmarks
    template = """<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
     It will be read and overwritten.
     DO NOT EDIT! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
    <DT><H3 ADD_DATE="{timestamp}" LAST_MODIFIED="{timestamp}">Imported From Arc</H3>
    <DL><p>
{bookmarks}
    </DL><p>
</DL><p>"""

    # Generate bookmark entries
    bookmark_entries = []
    for url in urls:
        title = get_title_from_url(url)
        bookmark_entry = f'        <DT><A HREF="{url}">{title}</A>'
        bookmark_entries.append(bookmark_entry)

    # Join all bookmarks with newlines
    bookmarks_content = "\n".join(bookmark_entries)

    # Fill the template
    output_content = template.format(
        timestamp=current_timestamp, bookmarks=bookmarks_content
    )

    # Write to file
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(output_content)


def main(input_file):
    """Main function to process input file and generate bookmarks."""
    # Read input file
    with open(input_file, "r", encoding="utf-8") as f:
        content = f.read()

    # Extract URLs
    urls = extract_urls_from_text(content)

    # Remove duplicates while preserving order
    urls = list(dict.fromkeys(urls))

    # Generate output filename
    output_file = "firefox_bookmarks.html"

    # Generate bookmarks file
    generate_firefox_bookmarks(urls, output_file)
    print(f"Generated {output_file} with {len(urls)} bookmarks")


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Usage: python script.py input_file.txt")
        sys.exit(1)

    input_file = sys.argv[1]
    if not os.path.exists(input_file):
        print(f"Error: File {input_file} not found")
        sys.exit(1)

    main(input_file)
