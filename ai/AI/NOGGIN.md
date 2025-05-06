# Noggin Gateway & Frontend-Backend Integration

This document provides a comprehensive overview of the Noggin gateway and how it integrates frontend applications with backend services in the Anterior platform.

## Architecture Overview

The Anterior platform uses a sophisticated architecture with:

1. **Backend Services** (in `platform` repo) - Microservices handling business logic
2. **Frontend Applications** (in `vibes` repo) - React/TypeScript user interfaces
3. **Noggin Gateway** (`platform/gateways/noggin`) - Central API gateway and static app server
4. **S3 Storage** - Stores frontend assets and user files (like PDFs)

This architecture enables:
- Clean separation of concerns
- Consistent API patterns
- Centralized authentication
- Reliable static app serving 
- Enterprise-level isolation

## Core Components

### 1. App Framework (`lib-platform/src/app.ts`)

The foundation of all backend services is the `App` class in `lib-platform/src/app.ts`:

```typescript
export class App<TServiceMap extends ServiceMap, TAppContext extends object> {
  public readonly hono: Hono<{ Variables: TAppContext & BaseContext }>;
  public readonly logger: Logger;
  public readonly trpc = initTRPC...
  
  constructor(
    public readonly baseCtx: TAppContext,
    public readonly options: AppOptions,
    public readonly auth?: (req: Request) => Promise<{ userUid: string; enterpriseUid: string } | Response>
  ) { ... }
}
```

Key features:
- Built on [Hono](https://hono.dev/) for HTTP routing and handling
- Type-safe API endpoint definitions with schemas
- JWT authentication middleware
- Standardized error handling
- CORS support

### 2. Static App Serving

The `createStaticApp` function in `app.ts` enables serving frontend applications:

```typescript
export function createStaticApp({
  prefix,
  blobs,
  index = "index.html",
  env,
  shouldGenerateCSP = false,
}: {
  prefix: Path | "";
  blobs: ReadOnlyBlobStore;
  index?: string;
  env?: Record<string, string>;
  shouldGenerateCSP?: boolean;
}): Hono { ... }
```

This function:
1. Creates a Hono app that serves static files from S3
2. Handles path prefixing for route matching
3. Sets appropriate MIME types for files
4. Performs environment variable substitution
5. Applies Content Security Policy headers

### 3. Noggin Gateway Structure

The Noggin gateway serves two primary purposes:
1. Provide API endpoints for backend services
2. Serve frontend applications from S3

Each subdirectory contains app-specific endpoints:
- `src/pdfs/app.ts` - PDF processing API
- `src/auth/app.ts` - Authentication services
- `src/notes/app.ts` - Notes API
- App-specific APIs: `src/flonotes/app.ts`, `src/flopilot/app.ts`

Apps are dynamically loaded using `importAndMountNestedDirectoryApps`.

## PDF Processing Architecture

### PDF API Endpoints

The Noggin gateway provides these key PDF endpoints:

| Endpoint | Method | Purpose | Parameters/Body | Response |
|----------|--------|---------|-----------------|----------|
| `/process-pdf` | POST | Upload and process a PDF | `file` (PDF blob), optional `stemUid` | `{ stemUid: string, pdfUid: string }` |
| `/pdf-status/:stemUid/:pdfUid` | GET | Check processing status | URL params: stemUid, pdfUid | `{ status: "processing" \| "ready" \| "error", message?: string }` |
| `/pdf-extracts/:stemUid/:pdfUid` | GET | Retrieve extracted data | URL params: stemUid, pdfUid | JSON structure of extracted content |

### PDF Processing Flow

1. **Upload**: Frontend uploads PDF to Noggin
2. **Initial Storage**: Noggin stores raw PDF in S3
3. **Processing**: Noggin schedules an asynchronous workflow
4. **Extraction**: Workflow processes PDF and stores JSON extracts
5. **Status Check**: Frontend polls status endpoint until processing completes
6. **Retrieval**: Frontend fetches and displays extracted content

### Storage Structure

PDFs are stored with this S3 path structure:
- Raw PDFs: `stems/{enterpriseUid}/{stemUid}/{pdfUid}/raw.pdf`
- Extracted data: `stems/{enterpriseUid}/{stemUid}/{pdfUid}/extracts.json`

The "stem" concept represents a logical grouping of related documents, enabling contextual relationships.

## Frontend Deployment & Integration

### Deployment Flow

Frontend applications are deployed using the following process:

1. **Build**: The app is built using Vite
   ```bash
   npm run build
   ```

2. **Configure**: Environment variables are set
   ```bash
   export VITE_NOGGIN_HOST="http://localhost:20701"
   ```

3. **Upload**: Assets are uploaded to S3
   ```bash
   aws s3 sync dist/ "s3://$BUCKET_NAME/$APP_PREFIX/" \
     --endpoint-url "$LOCALSTACK_ENDPOINT" \
     --delete
   ```

4. **Access**: Apps are accessed through Noggin
   ```
   http://localhost:20701/flonotes
   ```

### S3 Directory Structure

Frontend assets are stored in S3 with this structure:
- `vibes/flonotes/` - FloNotes app assets
- `vibes/flopilot/` - FloPilot app assets
- `vibes/atlas/` - Atlas app assets

### API Communication

Frontend apps make API calls through Noggin:

```typescript
// Example from flonotes
export async function processPdf(
  fileData: number[],
  fileName: string,
  documentType: "clinical" | "criteria",
  stemUid?: string,
): Promise<ProcessPdfResponse> {
  // Builds and sends a multipart/form-data request to Noggin
  const response = await apiRequest(API_ENDPOINTS.processPdf, {
    method: "POST",
    body: formData,
  });
  
  return data;
}
```

## Frontend Application Examples

### 1. FloNotes App (`vibes/apps/flonotes`)

FloNotes provides advanced PDF viewing and annotation capabilities for clinical documentation.

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

### 2. FloPilot App (`vibes/apps/flopilot`)

FloPilot uses PDFs as context for AI-assisted interactions and chat functionality.

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

## Security Model

The Anterior platform implements robust security:

1. **Authentication**:
   - JWT tokens stored in HTTP-only cookies
   - Enterprise-specific isolation of resources
   - Role-based access controls

2. **Data Protection**:
   - Resources are stored in enterprise-specific S3 paths
   - All API calls require valid authentication
   - Processing results are isolated by enterprise

3. **Network Security**:
   - Controlled CORS for cross-origin requests
   - Content Security Policy for frontend applications
   - HTTPS enforcement in production

## Development Workflow

### Local Development Setup

1. Start the platform services:
   ```bash
   cd platform
   nix develop
   ant-all-services
   ```

2. Build and deploy a frontend app:
   ```bash
   cd vibes/apps/flonotes
   npm i
   ./deploy-local.sh
   ```

3. Access the app through Noggin:
   ```
   http://localhost:20701/flonotes
   ```

### Advanced Development

For faster development:
1. Stop Noggin in the process-compose screen
2. Copy environment variables from logs
3. Run Noggin separately:
   ```bash
   cd gateways/noggin
   source .env && npm run start | npx pino-pretty
   ```

## Integration Instructions

To integrate a new frontend app with Noggin:

### 1. Create API Client

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
    await new Promise(resolve => setTimeout(resolve, 
      Math.min(5000 * Math.pow(1.5, attempt), 30000)));
  }
  
  throw new Error("Processing timed out");
}
```

### 3. Create Deployment Script

```bash
#!/bin/bash
set -euo pipefail

# App configuration
APP_PREFIX="vibes/your-app"
BASE_PATH="/your-app"
BUCKET_NAME="local-bucket"
LOCALSTACK_ENDPOINT="http://localhost:4566"
VITE_NOGGIN_HOST="http://localhost:20701"

# Build frontend with environment variables
export VITE_NOGGIN_HOST="${VITE_NOGGIN_HOST}"
export BASE_PATH="${BASE_PATH}"
npm run build

# Deploy to S3
aws s3 sync dist/ "s3://$BUCKET_NAME/$APP_PREFIX/" \
  --endpoint-url "$LOCALSTACK_ENDPOINT" \
  --no-verify-ssl \
  --delete

echo "Deployed app to $VITE_NOGGIN_HOST$BASE_PATH"
```

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

3. **Static Assets Not Loading**:
   - Verify S3 upload was successful
   - Check for path/prefix configuration mismatches
   - Confirm Noggin is running and can access S3

4. **API Errors**:
   - Check Noggin logs for detailed error information
   - Verify authentication cookies are present
   - Check network requests in browser developer tools

### Debugging Steps

1. **Connection Verification**:
   ```bash
   # Check LocalStack availability
   curl -s --head "http://localhost:4566"
   ```

2. **Authentication Check**:
   ```javascript
   // Check for auth_indicator cookie
   document.cookie.includes("auth_indicator=true")
   ```

3. **S3 Content Verification**:
   ```bash
   aws s3 ls s3://local-bucket/vibes/flonotes/ \
     --endpoint-url "http://localhost:4566" --no-verify-ssl
   ```

4. **API Call Testing**:
   ```bash
   curl -v -H "Cookie: auth_token=YOUR_JWT_TOKEN" \
     "http://localhost:20701/auth/me"
   ```

## Extending the System

To add new functionality to the Noggin gateway:

1. **New API Endpoint**:
   - Create a new app.ts file in the appropriate directory
   - Define endpoints using the App framework
   - Add necessary validation schemas

2. **New Frontend App**:
   - Build the frontend app with Vite
   - Create deployment script
   - Deploy to S3 with the correct prefix

3. **New PDF Processing Capabilities**:
   - Add new processing flows in platform workflows
   - Extend the JSON schema for new data types
   - Update frontend components to display new data