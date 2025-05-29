#!/usr/bin/env python3
"""
Fast Arc to Chrome bookmarks converter
pip install httpx rich beautifulsoup4
"""

import sys
import asyncio
import httpx
from bs4 import BeautifulSoup
from rich.progress import track
from urllib.parse import urlparse


async def get_title(client, url):
    try:
        r = await client.get(url, timeout=3)
        return BeautifulSoup(r.text, "html.parser").title.string.strip()
    except:
        return urlparse(url).netloc.replace("www.", "") or url


async def main():
    if len(sys.argv) != 3:
        print("Usage: python convert.py urls.txt bookmarks.html")
        return

    # Read URLs
    with open(sys.argv[1]) as f:
        urls = [line.strip() for line in f if line.strip() and not line.startswith("#")]

    # Add https if missing
    urls = [url if url.startswith("http") else f"https://{url}" for url in urls]

    # Fetch titles concurrently
    limits = httpx.Limits(max_connections=100, max_keepalive_connections=20)
    async with httpx.AsyncClient(limits=limits) as client:
        tasks = [get_title(client, url) for url in urls]
        titles = await asyncio.gather(*tasks)

    # Generate HTML
    html = """<!DOCTYPE NETSCAPE-Bookmark-file-1>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
"""

    for url, title in zip(urls, titles):
        title = title.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        html += f'    <DT><A HREF="{url}">{title}</A>\n'

    html += "</DL><p>"

    with open(sys.argv[2], "w") as f:
        f.write(html)

    print(f"Converted {len(urls)} URLs in {sys.argv[2]}")


if __name__ == "__main__":
    asyncio.run(main())
