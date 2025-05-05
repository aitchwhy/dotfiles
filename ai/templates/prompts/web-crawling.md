# Web Crawling prompts

Used with
- [Spider Cloud](spider.cloud)
- Apify
- CLI ...

## Text

```
say “no” to any cookie banners found or pop modals.

TASK: Analyze and extract key knowledge from the web page. INPUT PARAMETERS: - URL: {url} - Page Title: {title} - Page Content: {html_content} - Current Time: {timestamp} EXTRACTION REQUIREMENTS: 1. Generate a concise title (10 words max) capturing the core topic 2. Produce a 3-sentence executive summary highlighting key claims/findings 3. Extract 5-7 core facts/concepts using bullet points 4. Identify primary entities (people, organizations, products, technologies) 5. Extract any numerical data, statistics, or quantifiable claims 6. Note publication date and source credibility indicators 7. Identify content category (research, news, opinion, tutorial, etc.) KNOWLEDGE INTEGRATION: 1. Compare new information with existing database entries 2. Flag contradictions with previously stored information 3. Identify relationships to existing knowledge nodes 4. Assign confidence level (1-5) for factual claims 5. Generate 3-5 keywords/tags for knowledge graph indexing OUTPUT FORMAT: - Structured JSON with all extraction fields - Citation metadata (URL, access date, title, author if available) - Confidence score for overall summary quality (1-5)
```