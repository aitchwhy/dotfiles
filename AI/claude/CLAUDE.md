# Consolidated Guide: Anterior Platform and Development Ecosystem

This guide consolidates information from various documents related to the Anterior Platform's architecture, development practices, and tooling.

**Part 1: The Anterior Platform**

## 1. Introduction & Core Principles

The Anterior Platform is built upon a microservices architecture, clearly separating backend services from frontend applications. Backend services are typically housed in the `platform` repository, while frontend UIs (React/TypeScript) reside in the `vibes` repository. Communication is facilitated through the Noggin gateway.

A core principle in the platform's development is a structured code generation pipeline:

**`schemas → codegen → gen → lib → app`**

-   **`schemas/`**: Language-agnostic specifications (Protobuf, OpenAPI, JSON-Schema) serve as the single source of truth.
-   **`codegen/`**: Contains containerized scripts that read from `schemas/` and write language-specific artifacts to `gen/`.
-   **`gen/`**: Stores the generated artifacts (Go structs, Pydantic models, TypeScript types, etc.), which are checked into version control.
-   **`lib/{go,ts,python}/`**: Hand-written shared libraries that provide ergonomic wrappers and business logic on top of the generated code.
-   **Application Layers**: Services, gateways, workflows, and frontends consume artifacts from both `gen/` and `lib/`.

This approach ensures consistency and reduces boilerplate code across the platform.

## 2. Authentication System

The Anterior platform implements a robust multi-step authentication flow designed for security and multi-tenant isolation.

### Overview & Flow

1.  **Login Form**: Users enter credentials (email/password) via static HTML pages (e.g., `/auth/login.html`).
2.  **OTP Verification**: A One-Time Password (OTP) is generated and sent to the user. The user verifies this on a dedicated page (e.g., `/auth/otp-verify.html`).
3.  **JWT Tokens**: Upon successful OTP verification, JWT access and refresh tokens are issued.
4.  **Cookie-Based Auth**: These tokens are stored in HTTP-only cookies.
    * `access_token`: Short-lived (15 minutes), e.g., `access_token=<JWT>; Path=/; HttpOnly; SameSite=Lax; Max-Age=900`.
    * `refresh_token`: Long-lived (30 days), e.g., `refresh_token=<JWT>; Path=/; HttpOnly; SameSite=Lax; Max-Age=43200`.
    * `auth_indicator`: A non-HttpOnly flag for frontend awareness, e.g., `auth_indicator=true; Path=/; SameSite=Lax; Max-Age=900`.
5.  **Enterprise/User Context**: The JWT carries enterprise and user information.

### JWT Structure and Context Extraction

JWTs contain crucial claims for identifying users and their enterprise/workspace affiliations.

**Example JWT Payload:**
```json
{
  "sub": "user123",
  "exp": 1683721200,
  "iat": 1683717600,
  "entr": {
    "enterprise456": "admin"
  },
  "wksp": {
    "workspace789": "enterprise456"
  }
}
sub: User's unique identifier.entr: Map of enterprise IDs to roles.wksp: Map of workspace IDs to their parent enterprise ID.The parseEnterpriseUserFromJwt function (typically in auth/jwt.ts) is responsible for extracting this context on the backend. It handles scenarios with single or multiple enterprise memberships, potentially using headers like X-Anterior-Enterprise-Id and X-Anterior-Workspace-Id for disambiguation.// Simplified concept from platform/gateways/noggin/src/auth/jwt.ts
export function parseEnterpriseUserFromJwt(ctx: BaseContext): TokenContext {
  if (!ctx.jwtPayload?.entr) {
    throw new HTTPException(401, { message: "Authentication required" });
  }
  // ... logic to determine enterpriseUid, role, workspaceUid ...
  return {
    enterpriseUid,
    role,
    workspaceUid,
    userUid: ctx.jwtPayload.sub,
  };
}
API Authentication & Token RefreshAPI Requests: Cookies are automatically included in requests to the same domain, so frontend applications generally don't need to manage tokens manually for API calls. The credentials: 'include' fetch option is important.Token Refresh: A /auth/refresh endpoint is designed to use the refresh_token to issue new access_token and refresh_token pairs, extending user sessions.Frontend Integration Example// Check if user is authenticated
function isAuthenticated() {
  return document.cookie.includes('auth_indicator=true');
}

// Redirect to login if not authenticated
if (!isAuthenticated()) {
  const currentPath = encodeURIComponent(window.location.pathname);
  window.location.href = `/auth/login.html?redirectTo=${currentPath}`;
}

// Logout
function logout() {
  document.cookie = 'auth_indicator=; Path=/; Max-Age=0';
  // Also clear access_token and refresh_token cookies similarly
  window.location.href = '/auth/login.html';
}
Security ConsiderationsHTTP-Only Cookies: Protects tokens from XSS attacks.SameSite Policy: Restricts cookie usage.JWT Expiration: Short-lived access tokens limit the window of exposure.Enterprise Isolation: Data access is confined to authorized enterprises.CSRF Protection: Planned for future implementation.E2E Testing for AuthenticationThe platform includes a system for managing authentication in End-to-End (E2E) tests.AuthStateManager (auth-state.ts): Persists authenticated browser state (cookies, local storage) between test runs to avoid repeated logins. It saves state with an expiration time.// Conceptual usage of AuthStateManager
const authManager = new AuthStateManager();
if (authManager.isValid()) {
  // Load saved state into browser context
} else {
  // Perform login, then save state:
  // await login(page);
  // await authManager.save(page.context());
}
OTP Handling (otp-handler.ts): Provides secure ways to retrieve OTPs for tests (from environment variables, a test API endpoint, or a default OTP). It supports obfuscation in logs.// Conceptual OTP retrieval
async function getTestOtp(options: OtpHandlerOptions): Promise<string> {
  // Priority: Env Var -> API Endpoint -> Default OTP
  // ...
}
Test Utilities (test-utils.ts): Provides a login() function that automates the entire login flow (email/password, OTP submission) for tests. It can store the auth state for reuse.Test Fixtures: Playwright test fixtures (e.g., mockOtpEnv) are used to isolate environment changes for specific tests, preventing interference.Configuration: E2E tests use environment variables (e.g., ANT_TEST_USER_EMAIL, ANT_TEST_USER_OTP) for credentials and behavior.3. Noggin Gateway & Frontend-Backend IntegrationNoggin serves as the central API gateway and static application server, bridging frontend applications (from the vibes repository) and backend services (in the platform repository).Role of NogginAPI Gateway: Exposes backend service endpoints.Static Asset Server: Serves built frontend applications from S3.Authentication Hub: Centralizes authentication logic.Core Application Framework (@platform/lib/ts/lib-platform/src/app.ts)The App class is the backbone for backend services, built using Hono for HTTP routing and middleware.// Simplified from lib-platform/src/app.ts
export class App<TServiceMap extends ServiceMap, TAppContext extends object> {
  public readonly hono: Hono<{ Variables: TAppContext & BaseContext }>;
  public readonly logger: Logger;
  // ... other properties like tRPC, auth middleware

  constructor(
    public readonly baseCtx: TAppContext,
    public readonly options: AppOptions,
    public readonly auth?: (req: Request) => Promise<{ userUid: string; enterpriseUid: string } | Response>
  ) {
    this.hono = new Hono();
    // ... setup middleware, logging, error handling, CORS
  }

  endpoint(config: EndpointConfig) {
    // ... logic to define a type-safe Hono route with validation
  }
}
Static App Serving (createStaticApp in app.ts)This function is crucial for serving frontend applications from a blob store (like S3).export function createStaticApp({
  prefix, // URL prefix for the app, e.g., "/flonotes"
  blobs,  // ReadOnlyBlobStore instance (S3)
  index = "index.html", // Default file to serve
  env,    // Environment variables for substitution in files
  shouldGenerateCSP = false, // Content Security Policy flag
}: StaticAppOptions): Hono {
  const staticApp = new Hono();
  // ... logic to serve files from blob store, handle MIME types,
  // perform environment variable substitution (e.g., replacing $VAR_NAME),
  // and set CSP headers.
  return staticApp;
}
Noggin Backend StructureNoggin dynamically loads service-specific applications (each typically an app.ts defining Hono routes) from its subdirectories (e.g., src/pdfs/app.ts, src/auth/app.ts). The importAndMountNestedDirectoryApps function handles this, creating an API structure that mirrors the directory layout.Frontend DeploymentFrontend applications (e.g., FloNotes, FloPilot from the vibes repository) are typically:Built: Using Vite (npm run build).Configured: Environment variables like VITE_NOGGIN_HOST and BASE_PATH are set during the build or deployment script.Uploaded to S3: Scripts like deploy-local.sh sync the dist/ folder to an S3 bucket under a specific prefix (e.g., s3://local-bucket/vibes/flonotes/).# Example from deploy-local.sh
APP_PREFIX="vibes/flonotes"
BASE_PATH="/flonotes" # URL path
BUCKET_NAME="local-bucket"
LOCALSTACK_ENDPOINT="http://localhost:4566"

aws s3 sync dist/ "s3://$BUCKET_NAME/$APP_PREFIX/" \
  --endpoint-url "$LOCALSTACK_ENDPOINT" \
  --delete
URL Routing & API CommunicationServing Apps: When a user visits a URL like http://localhost:20701/flonotes, Noggin uses createStaticApp to fetch vibes/flonotes/index.html (and other assets) from S3 and serve it.API Calls: Frontend apps make API requests to Noggin (e.g., /pdfs/process-pdf). Noggin routes these to the appropriate backend service. Authentication cookies are automatically included if credentials: 'include' is used in the fetch request.Environment VariablesFrontend apps receive environment variables:Build-time: Injected by Vite (e.g., VITE_NOGGIN_HOST).Run-time (via Noggin): Noggin's createStaticApp can substitute placeholders (e.g., $KEY) in served files (like index.html) with values.Security ModelAuthentication: JWT tokens in HTTP-only cookies.Authorization: Enterprise and user-level permissions enforced by backend services.CORS: Configured in Noggin to control cross-origin access.CSP: Content Security Policy headers can be applied by createStaticApp.4. PDF Processing and Chat CapabilitiesThe Anterior platform provides advanced features for handling PDF documents, including processing, extraction, and AI-powered chat interactions with PDF content.Architecture Overview (Flopilot, Noggin Chat)Frontend (e.g., FloPilot, FloNotes): Handles PDF uploads, displays processed content, and facilitates chat.Noggin Gateway:Provides API endpoints for PDF operations (/pdfs/process-pdfs, /pdfs/pdf-status/:stemUid/:pdfUid, /pdfs/pdf-extracts/:stemUid/:pdfUid).Hosts chat backend logic (/chat).Backend Workflows: Asynchronous processes for PDF parsing, text extraction, and potentially OCR or AI analysis.S3 Storage: Stores raw PDFs and their structured JSON extracts.Key Classes/Controllers (Frontend - Conceptual from Flopilot Chat and PDF Architecture):classDiagram
    class FloPilotRoot {
        +render()
    }
    class PromptBox {
        +handleAttachClick()
        +handleSend()
    }
    class PdfProcessController {
        +processPdf(files)
        +handlePdfChange()
        +isPdfProcessingMap
    }
    class ChatController {
        +handleSubmit(message)
        +append(message)
    }
    FloPilotRoot --> PromptBox
    PromptBox --> PdfProcessController
    FloPilotRoot --> ChatController
Noggin PDF API Endpoints & Processing FlowUpload (POST /pdfs/process-pdfs or /process-pdfs depending on Noggin's internal routing):Frontend sends PDF file(s) via FormData.Noggin extracts enterpriseUid from JWT, generates stemUid (a grouping ID) and pdfUid(s).Raw PDF is stored in S3: stems/{enterpriseUid}/{stemUid}/{pdfUid}/raw.pdf.An asynchronous workflow is scheduled for processing.Returns { stemUid, pdfUids }.Status Check (GET /pdfs/pdf-status/:stemUid/:pdfUid or /pdf-status/...):Frontend polls this endpoint.Backend checks processing status (e.g., by looking for the existence/status of the extracts.json file or a database record).Returns { status: "processing" | "ready" | "error", message?: string }.Retrieve Extracts (GET /pdfs/pdf-extracts/:stemUid/:pdfUid or /pdf-extracts/...):Once status is "ready", frontend fetches the processed JSON data.Extracts are typically stored in S3: stems/{enterpriseUid}/{stemUid}/{pdfUid}/extracts.json.Example PDF Extracts JSON Structure:{
  "result": {
    "metadata": { "title": "Document Title", "pages": 5 },
    "pages": [
      {
        "pageNumber": 1,
        "blocks": [
          { "id": "block-1", "text": "Example text content", "boundingBox": { "x1": 100, ... } }
        ]
      }
