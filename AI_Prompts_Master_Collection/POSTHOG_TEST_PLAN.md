# PostHog Integration Test Plan

This document outlines the test plan for verifying the PostHog analytics integration in FloPilot and FloNotes applications.

## Prerequisites

1. Local development environment setup
2. PostHog testing project/instance (can use PostHog Cloud free tier for testing)
3. PostHog API key for the test project

## Environment Setup

1. Add the following environment variables to your `.env.local` file in both apps:

```bash
# FloPilot/.env.local
VITE_POSTHOG_API_KEY=<your_test_project_api_key>
VITE_POSTHOG_HOST=https://app.posthog.com
VITE_POSTHOG_DEBUG=true # Enable verbose logging during testing

# FloNotes/.env.local
VITE_POSTHOG_API_KEY=<your_test_project_api_key>
VITE_POSTHOG_HOST=https://app.posthog.com
VITE_POSTHOG_DEBUG=true # Enable verbose logging during testing
```

## Test Cases

### 1. Page Visit Tracking

**Test Steps:**
1. Navigate to different routes in the application
2. Check PostHog dashboard for `$pageview` events
3. Verify that URL and referrer information is correctly captured

**Expected Results:**
- Each page navigation should result in a `$pageview` event in PostHog
- URL path should be correctly captured in the event properties

### 2. Session Replay

**Test Steps:**
1. Enable session recordings in PostHog project settings (if not already enabled)
2. Perform various user actions in the application
3. Check PostHog dashboard for session recordings

**Expected Results:**
- Session recordings should be captured in PostHog
- User interactions should be visible in the recordings

### 3. Template Usage Tracking

**Test Steps:**
1. Navigate to FloNotes application
2. Apply a template from the template menu
3. Click "Run" to generate content based on the template
4. Check PostHog dashboard for `template_reuse` event

**Expected Results:**
- `template_reuse` event should be captured in PostHog
- Event properties should include:
  - `template_name`: Name of the used template
  - `has_pdfs`: Boolean indicating if PDFs were attached
  - `pdf_count`: Number of attached PDFs

### 4. FloNote Creation Tracking

**Test Steps:**
1. Create a new FloNote
2. Check PostHog dashboard for `flonote_created` event

**Expected Results:**
- `flonote_created` event should be captured in PostHog
- Event properties should include:
  - `template_name`: Name of the template used (or "custom" if none)
  - `has_pdfs`: Boolean indicating if PDFs were attached
  - `pdf_count`: Number of attached PDFs
  - `has_template`: Boolean indicating if a template was used

### 5. Non-Template Query Tracking

**Test Steps:**
1. Create a custom query outside of a template
2. Run the query
3. Check PostHog dashboard for `query_run_without_template` event

**Expected Results:**
- `query_run_without_template` event should be captured in PostHog
- Event properties should include:
  - `has_pdfs`: Boolean indicating if PDFs were attached
  - `pdf_count`: Number of attached PDFs

### 6. PDF Processing Tracking

**Test Steps:**
1. Upload a PDF to the FloNotes application
2. Check PostHog dashboard for `flonote_pdf_added` event

**Expected Results:**
- `flonote_pdf_added` event should be captured in PostHog
- Event properties should include:
  - `pdf_uid`: Unique identifier for the PDF
  - `stem_uid`: Stem identifier for the PDF
  - `extract_count`: Number of extracts from the PDF

### 7. Helpfulness Rating

**Test Steps:**
1. Find a message/response with the helpfulness rating component
2. Click the thumbs up or thumbs down button
3. Check PostHog dashboard for `message_feedback` event

**Expected Results:**
- `message_feedback` event should be captured in PostHog
- Event properties should include:
  - `message_id`: Identifier for the rated message
  - `rating`: Either "helpful" or "unhelpful"
  - `query`: The original query
  - `response_length`: Length of the response text

### 8. CSAT Survey

**Test Steps:**
1. Find a CSAT survey in the application
2. Select a rating (1-5)
3. Add optional feedback text
4. Submit the survey
5. Check PostHog dashboard for `csat_rating` event

**Expected Results:**
- `csat_rating` event should be captured in PostHog
- Event properties should include:
  - `session_id`: Identifier for the current session
  - `rating`: Numeric rating value (1-5)
  - `feedback`: Text feedback (if provided)

## Verification in PostHog Dashboard

For each test case:
1. Navigate to the Events tab in PostHog
2. Filter for the specific event
3. Check that all expected properties are present and correctly formatted
4. For session replays, verify that the recordings match the expected user interactions

## Notes for Production Deployment

- Disable debug mode by setting `VITE_POSTHOG_DEBUG=false` or removing it
- Ensure the appropriate API key is set for each environment (development, staging, production)
- Consider implementing sampling for high-volume events in production
- Review data retention settings in PostHog for compliance with data regulations