# PDF Chat System: Authentication and Network Flow

This document explains the complete flow of authentication and networking between the frontend application and backend services for the PDF chat feature. It covers the authentication process, PDF processing, and chat interaction.

## 1. Architecture Overview

The PDF chat system consists of the following components:

- **Frontend UI**: React application at `/vibes/apps/flopilot/src/`
- **Backend Services**: Node.js services at `/platform/gateways/noggin/src/`
  - PDF Processing Service: `/platform/gateways/noggin/src/pdfs/`
  - Chat Service: `/platform/gateways/noggin/src/chat/`
- **Storage**: S3-compatible storage for PDFs and extracted data

## 2. Authentication Flow

### 2.1 Login Process

The system uses a JWT-based authentication system:

1. User logs in via the login form (`/login.html`)
2. The system creates a one-time password (OTP) and redirects to verification page
3. After OTP verification, the server issues two tokens:
   - `access_token`: Short-lived JWT containing user and enterprise information
   - `refresh_token`: Long-lived token for refreshing access

These tokens are stored as cookies:
```
Cookie: auth_indicator=true; access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...; refresh_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2.2 JWT Structure

The access token contains critical enterprise information:

```json
{
  "entr": {
    "ent_VRfC5vl0Fw5w_dcEVM-1w": "ADMIN"
  },
  "wksp": {
    "wksp_PnCmyFGy9fHwWgIOx_k5h": "ent_VRfC5vl0Fw5w_dcEVM-1w",
    "wksp_vBE6Z0LimBSHaF0bRZ5l2": "ent_VRfC5vl0Fw5w_dcEVM-1w"
  },
  "iss": "https://co-helm.com",
  "sub": "usr_BYZnJljHgUz_y4CLsSmTU",
  "aud": ["access"],
  "exp": 1746662704,
  "nbf": 1746661804,
  "iat": 1746661804,
  "jti": "jwt_kOtkgt504p1WtEZJpA83w"
}
```

The `enterpriseUid` (`ent_VRfC5vl0Fw5w_dcEVM-1w`) is extracted from this token and is required for all authenticated operations.

### 2.3 Token Extraction

Backend services extract the enterprise information using the `parseEnterpriseUserFromJwt` function from `/platform/gateways/noggin/src/auth/jwt.ts`:

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
    // Logic for multiple enterprises...
  }
  
  // ...
  
  return {
    enterpriseUid,
    role,
    workspaceUid,
    userUid: ctx.jwtPayload.sub,
  };
}
```

## 3. PDF Processing Flow

### 3.1 PDF Upload

The process begins when a user uploads PDFs through the UI in `prompt-box.tsx`:

```typescript
// From /vibes/apps/flopilot/src/view/prompt-box.tsx
const {
  processedFiles,
  onPdfChange,
  onRemovePdf,
  isPdfProcessingMap,
} = usePdfProcessController();
```

The `usePdfProcessController` hook handles the PDF upload:

```typescript
// From /vibes/apps/flopilot/src/controller/use-pdf-process-controller.ts
const { mutateAsync: processPdf } = useMutation({
  mutationKey: PDF_PROCESS_KEY,
  mutationFn: async (files: File[]) => {
    const formData = new FormData();
    files.forEach((file) => {
      formData.append("files[]", file);
    });
    
    const response = await fetch(
      `${env.VITE_NOGGIN_HOST}/process-pdfs`, // Note: No pdfs/ prefix
      {
        method: "POST",
        body: formData,
        credentials: "include", // Explicitly include credentials
      },
    );
    // ... process response
  },
});
```

This request includes the authentication cookies thanks to the `credentials: "include"` option:

```
"cookie": "auth_indicator=true; access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...; refresh_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 3.2 Backend PDF Processing

The backend endpoint `/pdfs/process-pdfs` in `/platform/gateways/noggin/src/pdfs/app.ts` handles the request:

1. It extracts the `enterpriseUid` from the JWT using `parseEnterpriseUserFromJwt`
2. Generates a `stemUid` and `pdfUid` for each uploaded file
3. Stores each PDF in S3 using a path structure: `stems/{enterpriseUid}/{stemUid}/{pdfUid}/raw.pdf`
4. Schedules a background flow for processing the PDF
5. Returns the `stemUid` and `pdfUids` to the client

```typescript
// From /platform/gateways/noggin/src/pdfs/app.ts
app.endpoint({
  method: "POST",
  body: processStemPdfSchema,
  response: stemPdfUidResponseSchema,
  route: "/process-pdfs",
  async handler(ctx) {
    const { enterpriseUid } = parseEnterpriseUserFromJwt(ctx);
    // ... process PDFs and store in S3
    return {
      stemUid,
      pdfUids: results.map((result) => result.pdfUid),
    };
  },
});
```

### 3.3 PDF Status Polling

After upload, the frontend polls the status of PDF processing:

```typescript
// From /vibes/apps/flopilot/src/controller/use-pdf-process-controller.ts
const combinedQueries = useQueries({
  queries: (processedFiles ?? []).map(({ pdfUid, stemUid }) => ({
    queryKey: [PDF_PROCESS_STATUS_KEY, pdfUid],
    queryFn: async () => {
      const response = await fetch(
        `${env.VITE_NOGGIN_HOST}/pdf-status/${stemUid}/${pdfUid}`, // No pdfs/ prefix
        { 
          method: "GET",
          credentials: "include", // Explicitly include credentials
        },
      );
      // ... process response
    },
    refetchInterval: (query) => {
      if (query.state.data?.status === "processing") {
        return 5_000; // Poll every 5 seconds while processing
      }
      return false;
    },
  })),
});
```

The backend status endpoint again extracts the `enterpriseUid` from the JWT and checks if the processed file exists in the proper S3 path.

## 4. Chat Interaction Flow

### 4.1 Chat Request

Once PDFs are processed, users can chat about them. The chat request is made through the `useChatController` hook:

```typescript
// From /vibes/apps/flopilot/src/controller/use-chat-controller.ts
// Custom fetcher function to ensure credentials are included
const customFetcher = async (url: string, options: RequestInit) => {
  return fetch(url, {
    ...options,
    credentials: "include", // This ensures cookies are sent with the request
  });
};

export function useChatController() {
  // ...
  const { messages, input, append, handleInputChange, handleSubmit, error } =
    useChat({
      api: `${env.VITE_NOGGIN_HOST}/`, // Direct to root endpoint, not /chat
      streamProtocol: "text",
      body: {
        stemUid,
        pdfUids,
      },
      fetcher: customFetcher, // Use our custom fetcher that includes credentials
      onError: (error) => {
        console.error("Chat error:", error);
      },
    });
  // ...
}
```

### 4.2 Authentication Issue and Solution

**The Critical Issue**: 

The AI SDK's `useChat` hook doesn't include cookies by default, unlike direct fetch calls from the browser. This caused 401 Unauthorized errors in the chat endpoint.

The solution is to implement a custom fetcher that explicitly includes credentials:

```typescript
const customFetcher = async (url: string, options: RequestInit) => {
  return fetch(url, {
    ...options,
    credentials: "include", // This ensures cookies are sent with the request
  });
};
```

This custom fetcher needs to be applied to all API requests to ensure authentication cookies are properly sent:

```typescript
// For chat endpoints
useChat({
  api: `${env.VITE_NOGGIN_HOST}/chat`,
  fetcher: customFetcher,
  // ...
})

// For PDF endpoints
const response = await fetch(
  `${env.VITE_NOGGIN_HOST}/pdfs/process-pdfs`,
  {
    method: "POST",
    body: formData,
    credentials: "include", // Ensure cookies are sent
  },
);
```
```

### 4.3 Backend Chat Processing

The chat endpoint handler in `/platform/gateways/noggin/src/chat/app.ts` requires the `enterpriseUid` to fetch PDF extracts from S3:

```typescript
async function getExtractsByPdfUid(
  ctx: RequestContext<ChatAppContext, "/", {}, unknown, unknown, ChatRequestBody>
) {
  const enterpriseUid = ctx.auth?.enterpriseUid;
  if (!enterpriseUid) {
    // The types think we can have an undefined auth context
    throw new HTTPException(401, { message: "Unauthorized" });
  }

  const { stemUid, pdfUids } = ctx.body;
  const s3Keys = pdfUids.map((pdfUid) => {
    return {
      s3Key: buildS3PdfPath({
        enterpriseUid,
        stemUid,
        pdfUid,
        filename: "extracts.json",
      }),
      pdfUid,
    };
  });

  // Fetch and process PDF extracts from S3
  // ...
}
```

## 5. S3 Path Structure

The system uses a consistent S3 path structure for both raw PDFs and their extracted content:

```
stems/{enterpriseUid}/{stemUid}/{pdfUid}/raw.pdf
stems/{enterpriseUid}/{stemUid}/{pdfUid}/extracts.json
```

This structure is created by the `buildS3PdfPath` function used in both PDF and chat services:

```typescript
function buildS3PdfPath({ enterpriseUid, stemUid, pdfUid, filename }: BuildS3PdfPathArgs): string {
  const basePath = `stems/${enterpriseUid}/${stemUid}/${pdfUid}`;
  return `${basePath}/${filename}`;
}
```

## 6. Flow Diagram

### Authentication and PDF Processing:
```
User → Login → JWT Token Issued
↓
Upload PDF → /pdfs/process-pdfs → Extract enterpriseUid from JWT
↓
Generate stemUid and pdfUid → Store PDF in S3 at stems/{enterpriseUid}/{stemUid}/{pdfUid}/raw.pdf
↓
Schedule PDF processing flow → Process PDF → Store extracts in S3 at stems/{enterpriseUid}/{stemUid}/{pdfUid}/extracts.json
↓
Frontend polls /pdfs/pdf-status/{stemUid}/{pdfUid} → Wait until status is "ready"
```

### Chat Flow:
```
User sends message → useChat hook with custom fetcher → POST to /chat
↓
Backend extracts enterpriseUid from JWT → Get PDF extracts from S3 at stems/{enterpriseUid}/{stemUid}/{pdfUid}/extracts.json
↓
Format extracts and prompt → Send to LLM → Return response to user
```

## 7. Network Logs Analysis

The server logs show the full request/response cycle:

1. **Authentication**: Successful authentication with OTP verification
   ```
   [19:50:04.477] INFO (52868): Request completed
       res: {
         "status": 200,
         "headers": {}
       }
       req: {
         "url": "/otp/verify",
         "method": "POST",
         ...
   ```

2. **PDF Upload**: Successful upload with authentication cookies
   ```
   [19:50:24.719] INFO (52868): Request completed
       res: {
         "status": 200,
         "headers": {}
       }
       req: {
         "url": "/process-pdfs",  // Server log shows just the path portion
         "method": "POST",
         "headers": {
           ...
           "cookie": "auth_indicator=true; access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...; refresh_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
           ...
         },
   ```

3. **PDF Status Polling**: Successful status checks
   ```
   [19:50:24.743] INFO (52868): Request completed
       res: {
         "status": 200,
         "headers": {}
       }
       req: {
         "url": "/pdf-status/stm_4b5aaa396d_391899ebd3/pdf_a67de8344c_c8d574d08b",  // Server log shows just the path portion
         "method": "GET",
         ...
   ```

4. **Chat Request Failure**: The 401 error when cookies aren't properly included
   ```
   [19:50:48.504] ERROR (52868): Unauthorized
       res: {
         "status": 401,
         "headers": {}
       }
       req: {
         "url": "/",  // Server log shows path as root, but full URL is likely /chat
         "method": "POST",
         ...
   ```

## 8. Conclusion

The PDF Chat system requires consistent authentication across all endpoints. The critical issue needed to be fixed:

**Authentication Issue**: The AI SDK's fetch implementation wasn't including credentials by default. By adding a custom fetcher that explicitly includes credentials with `credentials: "include"`, we ensure the auth token is passed to the chat endpoint, allowing it to extract the `enterpriseUid` and access the correct PDF extracts in S3.

**Note about server logs**: The server logs show the paths without the full URL prefix, but in the frontend code, we still need to use the complete paths with prefixes:
- Frontend uses: `/pdfs/process-pdfs` while server logs show: `/process-pdfs`
- Frontend uses: `/pdfs/pdf-status/${stemUid}/${pdfUid}` while server logs show: `/pdf-status/...`
- Frontend uses: `/chat` while server logs show: `/`

By adding the credentials to all fetch requests, we ensure:
1. All requests are properly authenticated with the JWT token
2. The backend can extract the enterpriseUid from the JWT
3. The backend can correctly access the S3 paths containing the PDF extracts

The entire system is built around the concept of enterprise-scoped data, with all storage paths containing the enterprise ID extracted from the JWT. This ensures data isolation between enterprises while maintaining a consistent access pattern across services.