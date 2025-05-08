# Authentication System in Anterior Platform

This document explains how authentication works in the Anterior platform, focusing on the integration between the frontend applications and the Noggin gateway.

## Overview

The Anterior platform implements a multi-step authentication flow:

1. **Login Form** - Users enter credentials (email/password)
2. **OTP Verification** - One-time password sent to user
3. **JWT Tokens** - Upon verification, JWT tokens are issued
4. **Cookie-Based Auth** - Tokens stored in HTTP-only cookies
5. **Enterprise/User Context** - JWT carries enterprise and user information

This system provides secure authentication while maintaining multi-tenant isolation between enterprises.

## Authentication Flow

### 1. Login Process

The authentication process begins when a user visits the login page:

```
/auth/login.html
```

The login page is a static HTML file that presents a form for email and password entry. When submitted, the form sends a POST request to:

```
/auth/login
```

The backend then:
1. Validates the credentials
2. Generates a one-time password (OTP)
3. Redirects the user to the OTP verification page

### 2. OTP Verification

The OTP verification page is accessed at:

```
/auth/otp-verify.html
```

Users enter the OTP they received, and the form submits to:

```
/auth/otp/verify
```

Upon successful OTP verification, the backend:
1. Generates JWT access and refresh tokens
2. Sets HTTP-only cookies containing these tokens
3. Redirects the user to the requested application

### 3. Cookie Management

The system sets three cookies for authentication:

1. **access_token** - Short-lived JWT token (15 minutes)
   ```
   access_token=<JWT>; Path=/; HttpOnly; SameSite=Lax; Max-Age=900
   ```

2. **refresh_token** - Long-lived token for refreshing access (30 days)
   ```
   refresh_token=<JWT>; Path=/; HttpOnly; SameSite=Lax; Max-Age=43200
   ```

3. **auth_indicator** - Non-HTTP-only flag for frontend
   ```
   auth_indicator=true; Path=/; SameSite=Lax; Max-Age=900
   ```

The `HttpOnly` flag prevents JavaScript from accessing the tokens, protecting against XSS attacks, while the third cookie allows the frontend to know the user is authenticated.

## JWT Structure and Enterprise Context

The JWT tokens contain important claims:

```json
{
  "sub": "user123",        // User ID
  "exp": 1683721200,       // Expiration time
  "iat": 1683717600,       // Issued at time
  "entr": {                // Enterprise memberships
    "enterprise456": "admin"
  },
  "wksp": {                // Workspace memberships
    "workspace789": "enterprise456"
  }
}
```

Key components:
- `sub`: The user's unique identifier
- `entr`: Map of enterprise IDs to roles
- `wksp`: Map of workspace IDs to enterprise IDs

This structure enables:
1. Multi-enterprise support (users can belong to multiple enterprises)
2. Role-based access control within each enterprise
3. Workspace context within enterprises

### JWT Parsing and Context Extraction

The `jwt.ts` file handles extraction of enterprise and user information from the JWT payload:

```typescript
export function parseEnterpriseUserFromJwt(ctx: BaseContext): TokenContext {
  if (!ctx.jwtPayload?.entr) {
    throw new HTTPException(401, { message: "Authentication required" });
  }

  // Get enterprise and user uids from the token.
  let enterpriseUid = undefined;
  let role = undefined;

  // Most tokens will have a single enterprise.
  if (Object.keys(ctx.jwtPayload.entr).length === 1) {
    enterpriseUid = Object.keys(ctx.jwtPayload.entr)[0] as string;
    role = ctx.jwtPayload.entr[enterpriseUid];
  } else {
    // If token contains multiple enterprises.
    // First check for the X-Anterior-Enterprise-Id header.
    const entHeader = ctx.req.headers.get("X-Anterior-Enterprise-Id");
    if (entHeader && ctx.jwtPayload.entr[entHeader]) {
      enterpriseUid = ctx.jwtPayload.entr[entHeader];
      role = ctx.jwtPayload.entr[enterpriseUid];
    } else {
      // Use the first enterprise in the map (random).
      enterpriseUid = Object.keys(ctx.jwtPayload.entr)[0] as string;
      role = ctx.jwtPayload.entr[enterpriseUid];
    }
  }
  
  // Get workspaceUid from claims or header if present.
  let workspaceUid = undefined;
  const wksp = ctx.jwtPayload.wksp;
  if (Object.keys(wksp).length === 1) {
    // Token has a single workspace.
    Object.entries(wksp).forEach(([wkId, entId]) => {
      if (entId !== enterpriseUid) {
        throw new HTTPException(401, {
          message: "Workspace in token does not match enterprise",
        });
      }
      workspaceUid = wkId;
    });
  } else {
    // Token claims contain multiple workspaces. Look for
    // the X-Anterior-Workspace-Id header.
    const wkspHeader = ctx.req.headers.get("X-Anterior-Workspace-Id");
    if (wkspHeader) {
      const entId = wksp[wkspHeader];
      if (!entId) {
        throw new HTTPException(401, {
          message: "Workspace from header not found in token",
        });
      }
      if (entId !== enterpriseUid) {
        throw new HTTPException(401, {
          message: "Workspace in header does not match enterprise",
        });
      }
      workspaceUid = wkspHeader;
    }
  }

  return {
    enterpriseUid,
    role,
    workspaceUid,
    userUid: ctx.jwtPayload.sub,
  };
}
```

## API Authentication

When making API requests, the frontend doesn't need to manually handle tokens since the cookies are automatically included in requests to the same domain.

For enterprise-specific contexts, the frontend can include headers:
- `X-Anterior-Enterprise-Id`: Selects which enterprise context to use
- `X-Anterior-Workspace-Id`: Selects a specific workspace within the enterprise

## Token Refresh Mechanism

While not fully implemented in the current code, the system has a token refresh endpoint at:

```
/auth/refresh
```

The refresh flow is designed to:
1. Use the refresh_token cookie to authenticate
2. Generate new access and refresh tokens
3. Set new cookies with updated expiration times

This allows for session persistence without requiring users to log in frequently.

## Frontend Integration

The FloNotes app integrates with this auth system through:

1. **Login Page** - Static HTML served from S3 through Noggin
2. **Client JavaScript** - Handles form submission and error display
3. **Auth Detection** - Checks for the `auth_indicator` cookie

When a user attempts to access the app, the frontend checks for the auth cookie and redirects to login if not present.

## Security Considerations

The auth system implements several security best practices:

1. **HTTP-Only Cookies** - Prevents JavaScript access to tokens
2. **SameSite Policy** - Restricts cookie use to same-site contexts
3. **JWT Expiration** - Short-lived access tokens (15 minutes)
4. **Enterprise Isolation** - Data access limited to authorized enterprises
5. **CSRF Protection** - Planned but not yet implemented

## E2E Testing Authentication

The Anterior platform includes a robust system for handling authentication in end-to-end (E2E) tests. This system is designed to be secure, reusable, and configurable for different testing scenarios.

### Auth State Management

The `AuthStateManager` class in `auth-state.ts` provides persistent storage of authentication state between test runs:

```typescript
export class AuthStateManager {
  private baseDir: string;
  private filename: string;
  private autoCreateDir: boolean;
  private expirationTimeMs: number;

  constructor(options: AuthStateManagerOptions = {}) {
    this.baseDir = options.baseDir || path.join(process.cwd(), '.auth');
    this.filename = options.filename || 'user.json';
    this.autoCreateDir = options.autoCreateDir !== false;
    // Default to 24 hours expiration
    this.expirationTimeMs = options.expirationTimeMs || 24 * 60 * 60 * 1000;

    if (this.autoCreateDir && !fs.existsSync(this.baseDir)) {
      fs.mkdirSync(this.baseDir, { recursive: true });
    }
  }

  // Saves the current browser authentication state to disk
  async save(context: BrowserContext): Promise<string> {
    const playwrightState = await context.storageState();
    const now = Date.now();
    
    const enhancedState: AuthState = {
      ...playwrightState,
      createdAt: now,
      expiresAt: now + this.expirationTimeMs
    };

    const filePath = this.getStoragePath();
    fs.writeFileSync(filePath, JSON.stringify(enhancedState, null, 2), 'utf-8');
    
    return filePath;
  }

  // Loads a saved authentication state
  load(): AuthState | null {
    const filePath = this.getStoragePath();
    
    if (!fs.existsSync(filePath)) {
      return null;
    }
    
    try {
      const fileContent = fs.readFileSync(filePath, 'utf-8');
      return JSON.parse(fileContent) as AuthState;
    } catch (error) {
      console.error(`Error loading auth state from ${filePath}:`, error);
      return null;
    }
  }

  // Checks if the saved auth state is still valid (not expired)
  isValid(): boolean {
    if (!this.exists()) return false;
    
    const state = this.load();
    if (!state) return false;
    
    const now = Date.now();
    
    return state.expiresAt 
      ? state.expiresAt > now
      : state.createdAt 
        ? (state.createdAt + this.expirationTimeMs) > now
        : false;
  }
}
```

This allows tests to:
1. Save authenticated browser state after login
2. Reuse that state in future test runs to avoid repeated logins
3. Automatically detect when saved auth is expired
4. Clean up old authentication state when needed

### OTP Handling

The `otp-handler.ts` module provides secure OTP handling for E2E tests:

```typescript
export const otpHandlerOptionsSchema = z.object({
  // Email associated with the OTP
  email: z.string().email(),

  // API endpoint for retrieving OTPs (if available in your environment)
  apiEndpoint: z.string().url().optional(),

  // Environment variable name for test OTP
  otpEnvVar: z.string().optional().default('ANT_TEST_OTP'),

  // Default OTP to use if other methods fail
  defaultOtp: z.string().optional().default('123456'),

  // Whether to obfuscate OTP in logs
  secureLogging: z.boolean().optional().default(true),

  // Optional Playwright request object for API calls
  request: z.any().optional()
});

// Retrieves an OTP for testing purposes with priority order:
// 1. From environment variable
// 2. From API endpoint
// 3. Default OTP
export async function getTestOtp(options: OtpHandlerOptions): Promise<string> {
  // Validate the options with zod schema
  const validatedOptions = otpHandlerOptionsSchema.parse(options);

  const {
    email,
    apiEndpoint,
    otpEnvVar,
    defaultOtp,
    secureLogging,
    request
  } = validatedOptions;

  // 1. Try from environment variable
  if (process.env[otpEnvVar]) {
    const otp = process.env[otpEnvVar];
    console.log(`Using OTP from environment variable ${otpEnvVar}${secureLogging ? ': [REDACTED]' : `: ${otp}`}`);
    return otp as string;
  }

  // 2. Try from API endpoint if provided
  if (apiEndpoint) {
    try {
      // Use Playwright request object if provided
      if (request) {
        const response = await request.get(`${apiEndpoint}?email=${encodeURIComponent(email)}`);
        if (response.ok()) {
          const data = await response.json() as OtpApiResponse;
          if (data && data.otp) {
            console.log(`Retrieved OTP from API${secureLogging ? ': [REDACTED]' : `: ${data.otp}`}`);
            return data.otp;
          }
        }
      } else {
        // Use native fetch if no request object provided
        const response = await fetch(`${apiEndpoint}?email=${encodeURIComponent(email)}`);
        if (response.ok) {
          const data = await response.json() as OtpApiResponse;
          if (data && data.otp) {
            console.log(`Retrieved OTP from API${secureLogging ? ': [REDACTED]' : `: ${data.otp}`}`);
            return data.otp;
          }
        }
      }
    } catch (error) {
      console.warn('Failed to retrieve OTP from API:', error);
    }
  }

  // 3. Use default OTP
  console.log(`Using default OTP for testing${secureLogging ? ': [REDACTED]' : `: ${defaultOtp}`}`);
  return defaultOtp;
}

// Fills and submits the OTP in a test environment
export async function submitOtp(page: Page, otp: string): Promise<boolean> {
  try {
    // Wait for OTP input field
    await page.waitForSelector('input[name="otp"]');

    // Fill the OTP field
    await page.fill('input[name="otp"]', otp);

    // Submit the form
    await Promise.all([
      page.click('button[type="submit"]'),
      page.waitForResponse(response =>
        response.url().includes('/auth') &&
        response.status() < 400
      )
    ]);

    // Check for auth cookie to verify success
    const cookies = await page.context().cookies();
    const hasAuthCookie = cookies.some(cookie => cookie.name === 'auth_indicator');

    return hasAuthCookie;
  } catch (error) {
    console.error('Error submitting OTP:', error);
    return false;
  }
}
```

An important enhancement in the current implementation is the support for using Playwright's `request` object, which provides more consistent network handling in tests.

### Test Utilities

The `test-utils.ts` file provides a complete login workflow for tests:

```typescript
export interface LoginOptions {
  authDir?: string;
  storeAuthState?: boolean;
  expirationTimeMs?: number;
  reuseAuth?: boolean;
  secureLogging?: boolean;
}

export async function login(
  page: Page,
  options?: LoginOptions,
) {
  const {
    ANT_NOGGIN_BASE_URL,
    ANT_TEST_USER_EMAIL,
    ANT_TEST_USER_PASSWORD,
    ANT_TEST_USER_OTP,
    ANT_TEST_USER_STORE_AUTH_STATE,
    ANT_TEST_USER_AUTH_DIR,
    ANT_TEST_USER_SECURE_LOGGING,
    ANT_TEST_USER_API_ENDPOINT,
  } = envVarsSchema.parse(process.env);

  const storeAuthState = options?.storeAuthState ?? ANT_TEST_USER_STORE_AUTH_STATE ?? false;
  const secureLogging = options?.secureLogging ?? ANT_TEST_USER_SECURE_LOGGING ?? false;

  const authDir = options?.authDir || ANT_TEST_USER_AUTH_DIR || path.join(process.cwd(), '.auth');
  if (storeAuthState && !fs.existsSync(authDir)) {
    fs.mkdirSync(authDir, { recursive: true });
  }

  const result: LoginResult = {
    success: false,
    redirected: false,
    authCookie: null,
    accessToken: null,
    storageStatePath: storeAuthState ? path.join(authDir, 'user.json') : null,
    error: null,
  };

  try {
    // Login with email and password
    await page.goto(`${ANT_NOGGIN_BASE_URL}/auth/login.html`);
    await page.waitForSelector('input[name="email"]');
    await page.fill('input[name="email"]', ANT_TEST_USER_EMAIL);
    await page.fill('input[name="password"]', ANT_TEST_USER_PASSWORD);
    await page.click('button[type="submit"]');

    // Wait for OTP verification page
    await page.waitForURL(/otp-verify\.html/);

    // Get OTP securely
    let otp = ANT_TEST_USER_OTP;
    if (!otp) {
      const otpOptions: OtpHandlerOptions = {
        email: ANT_TEST_USER_EMAIL,
        secureLogging: secureLogging,
        otpEnvVar: 'ANT_TEST_OTP',
        defaultOtp: '123456'
      };

      // Only add apiEndpoint if defined
      if (ANT_TEST_USER_API_ENDPOINT) {
        otpOptions.apiEndpoint = ANT_TEST_USER_API_ENDPOINT;
      }

      otp = await getTestOtp(otpOptions);
    } else if (secureLogging) {
      console.log('Using provided OTP: [REDACTED]');
    } else {
      console.log(`Using provided OTP: ${otp}`);
    }

    // Submit OTP
    const otpSuccess = await submitOtp(page, otp);

    if (!otpSuccess) {
      throw new Error('OTP verification failed');
    }

    // Check for redirect
    try {
      await Promise.race([
        page.waitForURL(/\/flonotes/, { timeout: 10000 }),
        page.waitForURL(/\/health/, { timeout: 10000 })
      ]);
      result.redirected = true;
    } catch (error) {
      console.warn('Failed to detect redirect, checking cookies instead');
    }

    // Verify authentication cookies
    const cookies = await page.context().cookies();
    result.authCookie = cookies.find(cookie => cookie.name === 'auth_indicator');
    result.accessToken = cookies.find(cookie => cookie.name === 'access_token');

    if (!result.authCookie) {
      throw new Error('Authentication failed: No auth_indicator cookie found');
    }

    // Store authentication state if requested
    if (storeAuthState && result.storageStatePath) {
      await page.context().storageState({ path: result.storageStatePath });
    }

    result.success = true;

  } catch (error) {
    result.error = error instanceof Error ? error : new Error(String(error));
    if (storeAuthState) {
      // Take a screenshot of failure for debugging
      const screenshotPath = path.join(authDir, 'auth-failure.png');
      await page.screenshot({ path: screenshotPath });
    }
  }

  return result;
}

export async function verifyAuthenticated(page: Page): Promise<boolean> {
  const cookies = await page.context().cookies();
  return !!cookies.find(cookie => cookie.name === 'auth_indicator');
}
```

### Test Fixtures for OTP Testing

The `otp-handler.spec.ts` file introduces test fixtures for better isolation when testing OTP functionality:

```typescript
// Create a test fixture with mockable OTP environment
const test = base.extend<{ mockOtpEnv: undefined }>({
  // Mock environment for OTP testing
  mockOtpEnv: [async ({ }, use) => {
    // Save the original environment variable
    const originalOtp = process.env['ANT_TEST_OTP'];
    
    // Clear the variable for tests
    delete process.env['ANT_TEST_OTP'];
    
    // Allow tests to use the mock environment
    await use(undefined);
    
    // Restore the original value after tests
    if (originalOtp) {
      process.env['ANT_TEST_OTP'] = originalOtp;
    } else {
      delete process.env['ANT_TEST_OTP'];
    }
  }, { scope: 'test' }]
});
```

This approach isolates environment variable changes to specific test runs, preventing test interference.

### PDF API Testing

The PDF API tests in `pdf.spec.ts` show how protected endpoints can be accessed in tests:

```typescript
test("Upload, process, and retrieve extracts for PDF documents", async () => {
  // Process PDF (would fail without auth)
  const processPdfResponse = await fetch(PROCESS_PDFS_URL, {
    method: "POST",
    body: formData,
  });
  
  // Test remains of the API flow
  const { stemUid, pdfUid } = await processPdfResponse.json();
  
  // Poll for processing completion
  await expect
    .poll(
      async () => {
        const statusResponse = await fetch(PDF_STATUS_URL(stemUid, pdfUid));
        return statusResponse.status === 200;
      },
      {
        timeout: POLLING_TIMEOUT,
        intervals: [POLLING_INTERVAL],
      }
    )
    .toBeTruthy();
  
  // Check status and extracts
  // Verify results
});
```

In production code, these requests would include auth cookies automatically. In tests, the cookies are either:
1. Set up before the test using the `login()` function
2. Added manually to the request for isolated API tests
3. Bypassed in tests with a test-specific authentication mechanism

### Test Configuration

Tests use environment variables for configuration:

```typescript
// Environment variables for test auth
const envVarsSchema = z.object({
  ANT_NOGGIN_BASE_URL: z.string().url(),
  ANT_TEST_USER_EMAIL: z.string().email().default('test.user@anterior.com'),
  ANT_TEST_USER_PASSWORD: z.string().default('password123'),
  ANT_TEST_USER_OTP: z.string().optional(),
  ANT_TEST_USER_STORE_AUTH_STATE: z.boolean().optional(),
  ANT_TEST_USER_AUTH_DIR: z.string().optional(),
  ANT_TEST_USER_SECURE_LOGGING: z.boolean().optional(),
  ANT_TEST_USER_API_ENDPOINT: z.string().url().optional(),
});
```

This allows tests to be configured for different environments without code changes.

### Auth Test Scenarios

The tests in `auth.spec.ts` and `auth-state.spec.ts` cover key auth scenarios:

1. **Basic Authentication**: Verifying that login works with valid credentials
2. **OTP Source Flexibility**: Testing different ways to provide OTP codes
3. **Auth State Expiration**: Ensuring expired auth is handled correctly
4. **Auth State Reuse**: Confirming that saved auth state can be reused across test runs

### Security in Tests

The testing framework implements several security best practices:

1. **OTP Redaction**: Option to hide sensitive OTPs in logs
2. **Isolated Test Directories**: Separate directories for test auth state
3. **Automatic Cleanup**: Removing sensitive files after tests complete
4. **Env Var Configuration**: Using environment variables for credentials
5. **Validation**: Schema validation for all inputs and configuration
6. **Test Fixtures**: Isolated environment changes for test runs

## Implementation Components

The auth system consists of these key files:

1. **app.ts** - Main auth endpoints and cookie handling logic
2. **jwt.ts** - JWT parsing and enterprise/user context extraction
3. **auth-state.ts** - Manages authentication state for testing
4. **otp-handler.ts** - Handles OTP verification in tests
5. **test-utils.ts** - Provides authentication utilities for E2E tests
6. **test-e2e/*.spec.ts** - Test files for auth functionality

## Future Improvements

The current implementation has some noted areas for enhancement:

1. **CSRF Protection** - To be enabled when client is ready
2. **Refresh Token Implementation** - Fully functional token refresh flow
3. **Multiple Enterprise Support** - Improved UI for enterprise switching
4. **Workspace Context** - Better integration of workspace selection

## Integration Instructions

To add auth to a new frontend app:

1. **Check Auth State**
   ```javascript
   function isAuthenticated() {
     return document.cookie.includes('auth_indicator=true');
   }
   ```

2. **Redirect to Login if Needed**
   ```javascript
   if (!isAuthenticated()) {
     const currentPath = encodeURIComponent(window.location.pathname);
     window.location.href = `/auth/login.html?redirectTo=${currentPath}`;
   }
   ```

3. **Handle API Requests with Authentication**
   ```javascript
   // No need to manually add tokens - cookies are sent automatically
   fetch('/api/endpoint', {
     credentials: 'include',  // Important: include cookies
     headers: {
       'Content-Type': 'application/json',
       // Optional: specify enterprise context
       'X-Anterior-Enterprise-Id': currentEnterpriseId
     }
   });
   ```

4. **Logout Function**
   ```javascript
   function logout() {
     // Clear cookies by setting Max-Age=0
     document.cookie = 'auth_indicator=; Path=/; Max-Age=0';
     window.location.href = '/auth/login.html';
   }
   ```

5. **Adding E2E Tests for Auth**
   ```typescript
   import { login, verifyAuthenticated } from '../auth/test-utils';
   
   test('your protected feature', async ({ page }) => {
     // Login before testing protected features
     const result = await login(page);
     expect(result.success).toBe(true);
     
     // Now run your test with authentication in place
     await page.goto('/your-protected-page');
     // ...test assertions...
   });
   ```

6. **Testing with Custom OTP Values**
   ```typescript
   import { test as base } from '@playwright/test';
   
   // Create a fixture for OTP testing
   const test = base.extend({
     mockOtp: [async ({}, use) => {
       // Set a custom OTP for test
       const originalOtp = process.env['ANT_TEST_OTP'];
       process.env['ANT_TEST_OTP'] = '555555'; 
       
       await use(undefined);
       
       // Restore original
       if (originalOtp) {
         process.env['ANT_TEST_OTP'] = originalOtp;
       } else {
         delete process.env['ANT_TEST_OTP'];
       }
     }, { scope: 'test' }]
   });
   
   test('login with specific OTP', async ({ page, mockOtp }) => {
     // Test will use the mocked OTP value
     const result = await login(page);
     expect(result.success).toBe(true);
   });
   ```