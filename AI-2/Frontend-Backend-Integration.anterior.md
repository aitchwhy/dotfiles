# Frontend-Backend Integration in Anterior Platform

This document explains how the Vibes frontend applications integrate with the Platform backend through the Noggin service, with a focus on app deployment, serving, and API integration.

## Overview

The Anterior platform uses a sophisticated architecture to deploy and serve frontend applications:

1. **Vibes Repository**: Contains React/TypeScript frontend applications
2. **Platform Repository**: Houses the backend services including Noggin gateway
3. **S3 Storage**: Stores the built frontend assets
4. **Noggin Gateway**: Serves the frontend apps and proxies API requests

The key components involved in this integration are:

- `@platform/lib/ts/lib-platform/src/app.ts` - Core application framework
- `@platform/gateways/noggin/` - API gateway and frontend server
- `@vibes/apps/*/deploy-local.sh` - Frontend deployment scripts

## Application Framework (`lib-platform/src/app.ts`)

The `app.ts` file defines the core `App` class that powers all backend services in the platform. Key features:

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

Notable components:

1. **Hono Backend**: The app uses [Hono](https://hono.dev/) for HTTP routing, middleware, and handling
2. **Endpoint Definition**: Type-safe API endpoint definitions with schemas
3. **Auth Middleware**: JWT authentication support
4. **Error Handling**: Standardized error responses
5. **CORS Support**: Cross-origin resource sharing configuration

### Static App Serving

At the end of `app.ts` (lines 871-1018), there's a `createStaticApp` function that is crucial for serving frontend applications:

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

1. Creates a Hono app that serves static files from a blob store (S3)
2. Handles path prefixing to match the route structure
3. Applies proper MIME types based on file extensions
4. Supports environment variable substitution in served files
5. Applies Content Security Policy headers if needed

## Noggin Gateway Integration

The Noggin gateway (`@platform/gateways/noggin/`) serves two purposes:

1. Provide API endpoints for backend services
2. Serve frontend applications from S3

### Backend App Structure

Each subdirectory in Noggin contains its own `app.ts` file that defines a specific service:

- `src/pdfs/app.ts` - PDF processing API
- `src/auth/app.ts` - Authentication services
- `src/notes/app.ts` - Notes API
- `src/flonotes/app.ts` - FloNotes app-specific API
- `src/flopilot/app.ts` - FloPilot app-specific API

These services expose endpoints the frontend apps consume:

```typescript
export function createPdfApp(ctx: PdfAppContext, options: AppOptions): PdfApp {
  const app: PdfApp = new App(ctx, options);

  app.endpoint({
    method: "POST",
    body: processStemPdfSchema,
    response: stemPdfUidResponseSchema,
    route: "/process-pdf",
    async handler(ctx) { /* Implementation */ }
  });
  
  // Other endpoints like /pdf-status/:stemUid/:pdfUid and /pdf-extracts/:stemUid/:pdfUid
  
  return app;
}
```

### Directory-Based App Loading

Noggin dynamically loads all `app.ts` files from its subdirectories using `importAndMountNestedDirectoryApps` (lines 741-797). This creates an API structure mirroring the directory structure:

```typescript
export async function importAndMountNestedDirectoryApps(
  logger: Logger,
  app: Hono,
  basePath: string,
  baseRoute: string = ""
) {
  // Recursively find all app.ts files in subdirectories
  // and mount them at their corresponding paths
}
```

## Frontend Deployment Flow

The frontend applications in the Vibes repository are deployed using shell scripts:

### Build Process

Each app in the `vibes/apps/` directory has a `deploy-local.sh` script that:

1. Builds the React/TypeScript app with Vite
2. Configures environmental variables
3. Uploads the built assets to S3
4. Makes them available through Noggin

Key deployment variables:

```bash
# From flonotes/deploy-local.sh or flopilot/deploy-local.sh
APP_PREFIX="vibes/flonotes"  # or "vibes/flopilot"
BASE_PATH="/flonotes"        # or "/flopilot"
BUCKET_NAME="local-bucket"
LOCALSTACK_ENDPOINT="http://localhost:4566"
VITE_NOGGIN_HOST="http://localhost:20701"
```

The deployment scripts use AWS CLI to upload the built assets to S3:

```bash
aws s3 sync dist/ "s3://$BUCKET_NAME/$APP_PREFIX/" \
  --endpoint-url "$LOCALSTACK_ENDPOINT" \
  --no-verify-ssl \
  --delete
```

### S3 Directory Structure

The frontend assets are stored in S3 with the following structure:

- `vibes/flonotes/` - FloNotes app assets
- `vibes/flopilot/` - FloPilot app assets
- `vibes/atlas/` - Atlas app assets

## URL Routing

When a user visits a Noggin URL like `http://localhost:20701/flonotes`, the following happens:

1. Request arrives at Noggin gateway
2. Noggin's static app server handles the route
3. The path is used to determine which app to serve (`/flonotes` → `vibes/flonotes/`)
4. The static app fetches the appropriate files from S3
5. The frontend app is served with the correct content types

## API Communication

Frontend apps communicate with backend services through the Noggin gateway:

1. Frontend makes API requests to paths like `/pdfs/process-pdf`
2. Noggin routes these to the appropriate backend services 
3. JWT authentication cookies are automatically included in requests
4. Responses are returned to the frontend

For example, the FloNotes frontend uses API functions like:

```typescript
// From flonotes/src/services/noggin-api.ts
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
  
  // Return parsed response
  return data;
}
```

## Environment Variables

Frontend apps receive environment variables through two mechanisms:

1. **Build-time**: Variables defined in deployment scripts
   ```bash
   export VITE_NOGGIN_HOST="${VITE_NOGGIN_HOST}"
   export BASE_PATH="${BASE_PATH}"
   ```

2. **Run-time**: Text substitution in static files
   ```typescript
   // Text substitution in served files
   if (env) {
     for (const [key, value] of Object.entries(env)) {
       text = text.replaceAll(`$${key}`, value);
     }
   }
   ```

## Deployment Workflow

The complete workflow for deploying and running a Vibes frontend app:

1. Start the platform services
   ```bash
   cd platform
   nix develop
   ant-all-services
   ```

2. Build and deploy the frontend app
   ```bash
   cd vibes/apps/flonotes
   npm i
   ./deploy-local.sh
   ```

3. Access the app through Noggin
   ```
   http://localhost:20701/flonotes
   ```

## Security Model

The security model for frontend-backend integration includes:

1. **Authentication**: JWT tokens stored as HTTP-only cookies
2. **Authorization**: Enterprise and user-level permissions
3. **CORS**: Controlled cross-origin access
4. **CSP**: Content Security Policy for frontend applications

## Development Workflow

For faster development:

1. The Noggin service can be stopped in the process-compose screen
2. Environment variables can be copied from the logs
3. Noggin can be run separately with:
   ```bash
   cd gateways/noggin
   source .env && npm run start | npx pino-pretty
   ```

## Common Issues and Troubleshooting

1. **Connection Failures**: Ensure LocalStack is running
   ```bash
   # Check LocalStack availability
   curl -s --head "http://localhost:4566"
   ```

2. **Authentication Issues**: Verify cookies are being set properly
   ```javascript
   // Check for auth_indicator cookie
   document.cookie.includes("auth_indicator=true")
   ```

3. **Missing Assets**: Check S3 bucket contents
   ```bash
   aws s3 ls s3://local-bucket/vibes/flonotes/ --endpoint-url "http://localhost:4566" --no-verify-ssl
   ```

4. **API Errors**: Check Noggin logs for detailed error information