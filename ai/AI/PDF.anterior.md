# Anterior PDF Processing Architecture

This document details the PDF processing architecture used in the Anterior platform, specifically the integration between the `platform` repository's Noggin gateway and the `vibes` repository's frontend applications.

## Overview

The PDF processing system in Anterior follows a microservices architecture with:

1. **Backend Services** (in `platform` repo) - Handle PDF storage, processing, and extraction
2. **Frontend Applications** (in `vibes` repo) - Provide user interfaces for PDF upload, viewing, and analysis
3. **API Gateway** (Noggin) - Serves as the communication layer between frontends and backend services

This architecture allows for a clean separation of concerns while enabling sophisticated PDF processing capabilities across multiple applications.

## System Components

### 1. Noggin Gateway (`platform/gateways/noggin`)

The Noggin gateway acts as the primary API endpoint for all PDF operations, implemented in `src/pdfs/app.ts`.

#### Key Endpoints

| Endpoint | Method | Purpose | Parameters/Body | Response |
|----------|--------|---------|-----------------|----------|
| `/process-pdf` | POST | Upload and process a PDF | `file` (PDF blob), optional `stemUid` | `{ stemUid: string, pdfUid: string }` |
| `/pdf-status/:stemUid/:pdfUid` | GET | Check processing status | URL params: stemUid, pdfUid | `{ status: "processing" \| "ready" \| "error", message?: string }` |
| `/pdf-extracts/:stemUid/:pdfUid` | GET | Retrieve extracted data | URL params: stemUid, pdfUid | JSON structure of extracted content |

#### Authentication & Authorization

- Uses JWT-based authentication via HTTP-only cookies
- Extracts enterprise and user information from the JWT token
- Associates PDFs with specific enterprises for multi-tenant isolation

#### Implementation Details

1. **PDF Upload Process**:
   ```typescript
   // Creates a unique PDF ID and optionally a stem ID
   const pdfUid = generateRandomId("pdf");
   const stemUid = ctx.body.stemUid || generateRandomId("stm");
   
   // Stores the raw PDF in S3
   await ctx.platform.blobs.storeBlob(s3InputKey, blob, "application/pdf");
   
   // Schedules asynchronous processing
   await ctx.platform.flows.schedule(flowParams);
   ```

2. **Storage Structure**:
   - Raw PDFs: `stems/{enterpriseUid}/{stemUid}/{pdfUid}/raw.pdf`
   - Extracted data: `stems/{enterpriseUid}/{stemUid}/{pdfUid}/extracts.json`

3. **Error Handling**:
   - Maps common S3 errors to appropriate HTTP responses
   - Returns 404 for PDFs still processing or not found
   - Returns 500 for processing service failures

### 2. PDF Processing Flow

1. **Upload**: Frontend uploads PDF to Noggin
2. **Initial Storage**: Noggin stores raw PDF in S3
3. **Processing**: Noggin schedules an asynchronous workflow
4. **Extraction**: Workflow processes PDF and stores JSON extracts
5. **Status Check**: Frontend polls status endpoint until processing completes
6. **Retrieval**: Frontend fetches and displays extracted content

### 3. Vibes Apps Implementation

#### A. Flonotes App (`vibes/apps/flonotes`)

Flonotes provides advanced PDF viewing and annotation capabilities for clinical documentation.

**Key Components**:

1. **API Integration** (`src/services/noggin-api.ts`):
   - Complete client implementation for Noggin PDF endpoints
   - Handles authentication, error management, and retries
   - Implements status polling with exponential backoff

2. **PDF Processing** (`src/hooks/use-process-pdf.ts`):
   - Custom React hook that manages PDF processing state
   - Tracks upload progress, processing status, and results

3. **PDF Viewer** (`src/components/shell/pdf/`):
   - Rich PDF viewing UI with page navigation
   - Highlight and annotation capabilities
   - Citation linking between PDF content and notes

4. **IndexedDB Integration** (`src/indexed-db/db.ts`):
   - Local storage of PDF metadata and processing results
   - Enables offline viewing of previously processed PDFs

**Sample API Usage**:
```typescript
// Process a PDF and retrieve extractions
const extractsResponse = await processAndGetPdfExtracts(
  fileData,          // PDF binary data as number[]
  fileName,          // Original filename
  "clinical",        // Document type (clinical or criteria)
  undefined,         // Optional stemUid
  100,               // Max polling retries
  5000               // Polling interval (ms)
);
```

#### B. Flopilot App (`vibes/apps/flopilot`)

Flopilot uses PDFs as context for AI-assisted interactions and chat functionality.

**Key Components**:

1. **Controller Pattern** (`src/controller/use-pdf-process-controller.ts`):
   - State management for PDF processing
   - Integration with chat context

2. **PDF Models** (`src/controller/models/`):
   - `pdf-extracts.ts` - Types for extracted PDF content
   - `pdf-status.ts` - Status response handling
   - `process-pdf.ts` - PDF upload request models

3. **Chat Integration**:
   - Uses processed PDFs as context for AI-assisted chats
   - Links relevant PDF content to chat messages

## Technical Details

### 1. Stem Concept

A "stem" (`stemUid`) represents a logical grouping of related documents:

- Multiple PDFs can share the same `stemUid`
- Enables contextual relationships between documents
- Used for organizing documents in a case or workflow

### 2. Processing Pipeline

1. **PDF Upload**:
   - Multipart form data upload with optional metadata
   - Returns immediately with tracking IDs before processing completes

2. **Asynchronous Processing**:
   - Uses workflow engine for reliable, scalable processing
   - Extracts text, structure, and semantic information
   - Produces standardized JSON output

3. **Status Checking**:
   - Simple polling mechanism for checking completion
   - Returns processing, ready, or error states
   - Includes error details when processing fails

4. **Extract Retrieval**:
   - Fetches JSON representation of processed PDF
   - Structure includes text blocks, page information, and metadata
   - May include domain-specific extractions (clinical findings, etc.)

### 3. JSON Extract Structure

```json
{
  "result": {
    "metadata": {
      "title": "Document Title",
      "author": "Author Name",
      "pages": 5,
      "creationDate": "2023-01-15T12:00:00Z"
    },
    "pages": [
      {
        "pageNumber": 1,
        "blocks": [
          {
            "id": "block-1",
            "text": "Example text content",
            "boundingBox": {
              "x1": 100, "y1": 100,
              "x2": 400, "y2": 150
            },
            "type": "paragraph"
          }
          // More blocks...
        ]
      }
      // More pages...
    ],
    "structure": {
      // Document structure information
    }
  }
}
```

## Integration Instructions

To integrate PDF processing in a new vibes app:

### 1. Setup API Client

Create a service file that interfaces with Noggin PDF endpoints:

```typescript
// Example minimal API client
export async function processPdf(fileData: number[], fileName: string): Promise<{stemUid: string, pdfUid: string}> {
  const formData = new FormData();
  formData.append("file", new Blob([new Uint8Array(fileData)]), fileName);
  
  const response = await fetch(`${NOGGIN_HOST}/pdfs/process-pdf`, {
    method: "POST",
    body: formData,
    credentials: "include" // For auth cookies
  });
  
  if (!response.ok) {
    throw new Error(`PDF processing failed: ${response.status}`);
  }
  
  return await response.json();
}
```

### 2. Implement Status Polling

```typescript
export async function waitForProcessing(stemUid: string, pdfUid: string, maxRetries = 100): Promise<void> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const response = await fetch(`${NOGGIN_HOST}/pdfs/pdf-status/${stemUid}/${pdfUid}`, {
      credentials: "include"
    });
    
    if (!response.ok) {
      throw new Error(`Status check failed: ${response.status}`);
    }
    
    const status = await response.json();
    
    if (status.status === "ready") {
      return;
    }
    
    if (status.status === "error") {
      throw new Error(`Processing error: ${status.message}`);
    }
    
    // Wait before next check (with exponential backoff)
    await new Promise(resolve => setTimeout(resolve, Math.min(5000 * Math.pow(1.5, attempt), 30000)));
  }
  
  throw new Error("Processing timed out");
}
```

### 3. Fetch Extractions

```typescript
export async function getExtractions(stemUid: string, pdfUid: string): Promise<any> {
  const response = await fetch(`${NOGGIN_HOST}/pdfs/pdf-extracts/${stemUid}/${pdfUid}`, {
    credentials: "include"
  });
  
  if (!response.ok) {
    throw new Error(`Failed to get extractions: ${response.status}`);
  }
  
  return await response.json();
}
```

### 4. Complete Flow Example

```typescript
export async function processAndGetExtractions(file: File): Promise<any> {
  // Read file as array buffer
  const arrayBuffer = await file.arrayBuffer();
  const fileData = Array.from(new Uint8Array(arrayBuffer));
  
  // Upload and start processing
  const { stemUid, pdfUid } = await processPdf(fileData, file.name);
  
  // Wait for processing to complete
  await waitForProcessing(stemUid, pdfUid);
  
  // Get and return extractions
  return await getExtractions(stemUid, pdfUid);
}
```

## Deployment and Development Workflow

1. **Local Development**:
   - Start platform services: `nix develop` and `ant-all-services`
   - Build and deploy vibes app: `cd apps/your-app && npm i && ./deploy-local.sh`
   - Access via Noggin: `http://localhost:20701/your-app`

2. **Production Deployment**:
   - Vibes apps are built and uploaded to S3
   - Noggin serves them as static assets
   - API calls are proxied through Noggin to backend services

## Security Considerations

1. **Authentication**:
   - JWT tokens stored in HTTP-only cookies
   - Enterprise-specific isolation of PDFs
   - Role-based access controls for specific operations

2. **Data Protection**:
   - PDFs are stored in enterprise-specific S3 paths
   - All API calls require valid authentication
   - Processing results are isolated by enterprise

3. **Error Handling**:
   - User-friendly error messages
   - Detailed logging for debugging
   - Appropriate HTTP status codes

## Extending the System

To extend PDF processing capabilities:

1. **New Extraction Types**:
   - Add new processing flows in platform workflows
   - Extend the JSON schema for new data types
   - Update frontend components to display new data

2. **Additional Endpoints**:
   - Add new routes in Noggin's PDF app
   - Implement corresponding API clients in vibes apps

3. **Enhanced Visualization**:
   - Build new UI components for specialized PDF rendering
   - Implement domain-specific interactions (e.g., clinical annotations)

## Troubleshooting

### Common Issues

1. **PDF Upload Fails**:
   - Check authentication status (JWT token)
   - Verify file size within limits
   - Ensure file is valid PDF format

2. **Processing Never Completes**:
   - Check workflow service logs for errors
   - Verify S3 permissions are correct
   - Check for resource constraints in processing service

3. **Extract Retrieval Fails**:
   - Confirm processing has completed successfully
   - Verify S3 path is correct for the enterprise
   - Check for malformed JSON in extract file

### Debugging Tools

1. **API Request Logs**:
   - Check Noggin server logs for API request details
   - Look for HTTP status codes and error messages

2. **Storage Inspection**:
   - Use S3 tools to inspect raw PDFs and extracts
   - Verify file integrity and permissions

3. **Processing Status**:
   - Monitor workflow execution status
   - Check for failed or stalled workflows