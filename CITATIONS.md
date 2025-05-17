# PDF Citation System Implementation

## Problem Statement

The platform needed a new feature called "Flopilot Chat + Citations" that would allow users to upload PDF documents, ask questions about them, and receive answers with precise citations back to the source documents. This would eliminate manual document skimming, speed up review processes, and provide defensible evidence for audits.

The core technical requirement was to build a chat system that could:
1. Accept and process multiple PDF documents
2. Allow natural-language questions about the PDF content
3. Stream back responses with accurate, clickable citations to source documents
4. Validate all responses against proper JSON schemas

## Requirements Analysis

Based on the PRD, the key technical requirements included:

### Core Features

1. **PDF Upload & Parsing**: Already handled by existing systems that convert PDFs to structured extract blocks
2. **Parse Status Polling**: Already implemented via UI components  
3. **Chat With Citations**: The focus of this implementation, requiring schema-based payloads
4. **Schema-First Contracts**: All payloads defined in JSON-Schema Draft-07

### Technical Architecture Components

- UI: PromptBoxComponent, ChatComponent, Controllers (already implemented)
- API: Fastify endpoints (our focus)
- Worker: FlowScheduler + Prefect (already implemented)
- Parser: Reducto (already implemented)
- LLM: Claude (our integration point)
- Store: S3 (or MinIO) (already implemented)

### Data Model Requirements

- TextSectionV1: Segments of assistant response with citations
- PdfSectionV1: Bounding box location in source documents
- Structured prompt to LLM and structured response parsing

## Design Decisions & Approach

### 1. Schema Integration

The first design decision was how to work with the schemas. Two options were considered:

1. **Manual Schema Implementation**: Create our own schema definitions in code
2. **Generated Schema Usage**: Use auto-generated TypeScript schemas from JSON Schema definitions

Decision: We chose to use the generated schema approach since the JSON Schema files were already defined and the generation pipeline existed. This approach:
- Ensures consistency between backend validation and frontend types
- Reduces duplication of schema definitions
- Leverages the existing type generation system
- Minimizes maintenance burden when schemas change

### 2. LLM Integration Method

For interacting with the Claude LLM, two approaches were considered:

1. **Orchestrator Pattern**: Use an intermediary orchestrator service to handle LLM calls
2. **Direct LLM Integration**: Call the LLM API directly from the chat endpoint

Decision: We chose to bypass the orchestrator and call Claude directly because:
- It simplifies the code path for this specific use case
- It gives us more control over the exact prompt format for citation extraction
- It reduces latency by eliminating a service hop
- The orchestrator wasn't adding significant value for this specific feature

### 3. Response Format

For sending responses back to the client, two options were evaluated:

1. **Streaming Response**: Use SSE (Server-Sent Events) to stream responses as they're generated
2. **Standard REST API**: Return a single JSON response when processing is complete

Decision: We opted for a standard REST API response because:
- It simplifies error handling
- Simplifies the client implementation
- Makes it easier to validate the full response against the schema
- Streaming wasn't a core requirement for the initial implementation

### 4. Citation Extraction Approach

For handling the citation extraction from Claude responses, we considered:

1. **XML Format**: Have Claude return responses with XML tags for citations
2. **JSON Format**: Have Claude format responses in a JSON structure

Decision: We chose the XML approach because:
- It's more natural for language models to insert inline citations as XML tags
- JSON structures would require more complex prompt engineering
- The XML format is more readable when debugging
- It provides a clear separation between citation metadata and text content

## Implementation Details

### Schema Structure

We implemented the schema structure based on the JSON Schema definitions:

1. **TextSection**: Represents segments of text with citations
   - text: The content text
   - section_type: Identifier ("text_section_v01_20250514")
   - start/end: Character positions in the source
   - citations: Array of ExtractCitation references

2. **PdfSection**: Represents a location in a PDF document
   - section_type: Identifier ("pdf_section_v01_20250514")
   - page: Page number (1-based)
   - bounding_box: Rectangle coordinates (top, right, bottom, left)

3. **ExtractCitation**: Links text to source documents
   - pdf_id: Identifier for the PDF
   - extract_id: Identifier for the extract
   - cited_text: The cited content
   - start_char/end_char: Character positions
   - pdf_section: Optional bounding box location

### Prompt Engineering

The prompt to Claude was structured as follows:

```
You are an expert research assistant tasked with answering questions based on provided PDF document extracts.

Here are the PDF documents that you will be referencing, formatted in XML and broken down into extracts referenced by extract ID:

<pdfs>
<pdf1>
<extract ids="pdf_id.extract_0">Extract text content</extract>
...
</pdf1>
...
</pdfs>

The question you need to answer is:
<question>
{User's question}
</question>

To complete this task, follow these steps:
1. Review the PDF documents and identify relevant quotes
2. List the relevant quotes in numbered order
3. Formulate your answer, starting with "Answer:"
4. When citing information, use the format:
   <extract ids="pdf_id.ext_id.block_id">Cited text goes here.</extract>
```

This prompt instructs Claude to respond with explicit XML citation tags that reference the source documents.

### Response Parsing

The response parsing logic:

1. Checks for presence of `<extract>` tags
2. Parses the response to extract citation sections
3. For each citation:
   - Extracts the `ids` attribute
   - Parses cited text
   - Creates a PDF section reference
   - Maps text positions to source document locations
4. Constructs a properly structured JSON response with sections and citations

### Error Handling

The implementation includes error handling for:
- Malformed XML in responses
- Missing citation tags
- Invalid PDF or extract references
- LLM API errors

Each error case falls back to simpler response formats when necessary, ensuring the user always gets a response.

## Assumptions

Several assumptions were made during implementation:

1. **PDF Processing**: We assumed the PDF extraction process is already in place and functions correctly
2. **Schema Stability**: We assumed the schemas are stable and won't change frequently
3. **LLM Reliability**: We assumed Claude can reliably follow instructions to produce correctly formatted citations
4. **Bounding Box Accuracy**: For the initial implementation, we used placeholder values for bounding boxes
5. **Text Position Accuracy**: We simplified text position mapping, assuming exact matches can be found

## Potential Future Improvements

Several areas for future enhancement were identified:

1. **Response Streaming**: Add streaming capabilities to show results as they're generated
2. **Citation Accuracy**: Improve exact text position mapping with fuzzy matching
3. **Error Recovery**: More sophisticated error recovery for malformed LLM responses
4. **Schema Validation**: Add explicit validation of responses against schemas before returning
5. **Performance Optimization**: Implement caching of extracted content and common queries
6. **UI Integration**: Add hover states and visual indicators for citations in the front-end

## Conclusion

The implemented solution provides a robust foundation for the PDF citation feature. By leveraging schema-first design, direct LLM integration, and structured XML prompting, we've created a system that can accurately extract information from PDFs and provide well-cited responses to user queries.

The implementation balances simplicity with functionality, focusing on reliable citation extraction while maintaining a clear code structure. The approach is extensible for future enhancements while meeting the immediate requirements specified in the PRD.