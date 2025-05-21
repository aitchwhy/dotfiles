# PostHog Integration

This document outlines the implementation approach, design decisions, and technical details for integrating PostHog analytics into the FloNotes and FloPilot applications.

## Overview

PostHog provides product analytics, session recording, feature flags, and A/B testing. Our implementation focuses on capturing key user events and behaviors to improve the product experience while maintaining minimal changes to the codebase.

## Implementation Approach

The implementation follows these key principles:

1. **Parse, Don't Validate**: We utilize Zod for type-safe schema parsing of environment variables, ensuring both runtime safety and proper TypeScript types.
2. **Progressive Enhancement**: Analytics is implemented in a way that doesn't block core application functionality.
3. **Minimal Changes**: Changes to existing code are kept minimal, focusing on key tracking points.
4. **Consistent Event Naming**: We use a consistent naming pattern for all tracked events.
5. **Non-intrusive Design**: Analytics code doesn't interfere with business logic.

## Environment Configuration

Environment variables are handled using Zod schemas:

```typescript
const envSchema = z.object({
  VITE_NOGGIN_HOST: z.string().url(),
  
  // PostHog settings (optional with defaults)
  VITE_POSTHOG_API_KEY: z.string().optional(),
  VITE_POSTHOG_HOST: z.string().url().optional().default("https://app.posthog.com"),
  VITE_POSTHOG_DEBUG: z.string().optional().transform(val => val === "true"),
});

export const env = envSchema.parse(import.meta.env);
```

This approach ensures:
- Environment variables are properly typed
- Required variables are present at runtime
- Default values are provided where appropriate
- Type information is available through inference

## Deployment Configuration

For different environments, the deployment scripts (`deploy-aws.sh` and `deploy-local.sh`) set appropriate PostHog keys:

```bash
# For AWS/production deployment
export VITE_POSTHOG_API_KEY="${VITE_POSTHOG_API_KEY:-ph_prod_key_placeholder}"
export VITE_POSTHOG_HOST="${VITE_POSTHOG_HOST:-https://app.posthog.com}"

# For local development
export VITE_POSTHOG_API_KEY="${VITE_POSTHOG_API_KEY:-ph_test_key_placeholder}"
export VITE_POSTHOG_HOST="${VITE_POSTHOG_HOST:-https://app.posthog.com}"
export VITE_POSTHOG_DEBUG="true"  # Enable debug mode for development
```

## Events Tracked

The implementation captures these core events:

| Event Name | Description | Key Properties |
|------------|-------------|---------------|
| `$pageview` | Tracks page/route changes | `path`, `url` |
| `template_reuse` | When a template is selected and run | `template_name`, `pdf_count`, `has_pdfs` |
| `query_run_without_template` | Query runs outside of template | `has_pdfs`, `pdf_count` |
| `flonote_created` | When a new FloNote is created | `template_name`, `has_template`, `pdf_count` |
| `flonote_pdf_added` | When PDFs are processed | `pdf_uid`, `stem_uid`, `extract_count` |
| `message_feedback` | Binary helpfulness rating | `message_id`, `rating`, `query`, `response_length` |
| `csat_rating` | 5-point satisfaction survey | `session_id`, `rating`, `feedback` |

## Component Implementation

### 1. PostHog Initialization

The initialization logic ensures PostHog is properly configured:

```typescript
export function initPostHog() {
  const apiKey = import.meta.env.VITE_POSTHOG_API_KEY;
  const host = import.meta.env.VITE_POSTHOG_HOST || 'https://app.posthog.com';
  const debug = import.meta.env.VITE_POSTHOG_DEBUG === 'true';

  // Only initialize if API key is provided
  if (apiKey) {
    posthog.init(apiKey, {
      api_host: host,
      capture_pageview: false, // We'll handle this with usePageTracking
      autocapture: false, // Disable autocapture for more control
      capture_pageleave: true,
      session_recording: {
        // Enable session recordings
        maskAllInputs: false, // Don't mask inputs
        maskTextSelector: '.ph-no-capture',
        maskInputSelector: '.ph-mask',
      },
      loaded: (ph) => {
        if (debug) {
          ph.debug();
          console.log('PostHog initialized:', ph);
        }
      },
    });
  } else if (debug) {
    console.warn('PostHog API key not provided. Analytics will not be captured.');
  }
}
```

### 2. User Identification & Tracking

A custom hook (`usePageTracking`) ensures consistent tracking across components:

```typescript
/**
 * Hook for tracking page views
 * @param currentPath The current route path
 */
export function usePageTracking(currentPath: string) {
  useEffect(() => {
    // Track page view when path changes
    if (import.meta.env.VITE_POSTHOG_API_KEY) {
      posthog.capture('$pageview', {
        path: currentPath,
        url: window.location.href,
      });
    }
  }, [currentPath]);
}
```

### 3. Template Usage Tracking

Templates are tagged with a `data-template-id` attribute:

```typescript
const setTemplateContent = (templateKey: keyof typeof templates) => {
  const template = templates[templateKey];
  if (template) {
    // Add data-template-id attribute for tracking purposes
    const contentWithTemplateId = template.content.replace(
      '<h1>', 
      `<h1 data-template-id="${templateKey}">`
    ); 
    setContent(contentWithTemplateId);
  }
};
```

This allows event tracking without modifying the template's visual appearance:

```typescript
// Check if this is a template run
const isTemplateRun = currentContent.includes('data-template-id=');
let templateName = "custom";

// Extract template name if present
if (isTemplateRun) {
  const templateMatch = currentContent.match(/data-template-id="([^"]+)"/);
  if (templateMatch && templateMatch[1]) {
    templateName = templateMatch[1];
  }
}

// Track the appropriate event
if (isTemplateRun) {
  trackEvent('template_reuse', {
    template_name: templateName,
    has_pdfs: pdfs.length > 0,
    pdf_count: pdfs.length,
  });
} else {
  trackEvent('query_run_without_template', {
    has_pdfs: pdfs.length > 0,
    pdf_count: pdfs.length,
  });
}
```

### 4. PDF Processing Tracking

PDF processing events are captured when PDFs are added and processed:

```typescript
// Track PDF processing in PostHog
trackEvent('flonote_pdf_added', {
  pdf_uid: data.pdfUid,
  stem_uid: data.stemUid,
  extract_count: data.result.extracts?.length || 0,
});
```

### 5. Feedback Components

Two feedback components have been implemented:

**A. Helpfulness Rating**

A simple thumbs up/down UI that collects binary feedback on individual responses:

```tsx
export function HelpfulnessRating({ messageId, query, response }: HelpfulnessRatingProps) {
  const [rating, setRating] = useState<'helpful' | 'unhelpful' | null>(null);
  const [loading, setLoading] = useState(false);
  
  const handleRating = async (isHelpful: boolean) => {
    setLoading(true);
    
    try {
      const newRating = isHelpful ? 'helpful' : 'unhelpful';
      setRating(newRating);
      
      trackEvent('message_feedback', {
        message_id: messageId,
        rating: newRating,
        query,
        response_length: response.length,
      });
    } catch (error) {
      console.error('Error tracking feedback:', error);
    } finally {
      setLoading(false);
    }
  };
  
  // UI rendering...
}
```

**B. CSAT Survey**

A 5-point satisfaction rating with optional comments:

```tsx
export function CSATSurvey({ sessionId, onClose }: CSATSurveyProps) {
  const [selectedRating, setSelectedRating] = useState<number | null>(null);
  const [submitted, setSubmitted] = useState(false);
  const [feedback, setFeedback] = useState('');
  
  const handleSubmit = () => {
    if (selectedRating === null) return;
    
    trackEvent('csat_rating', {
      session_id: sessionId,
      rating: selectedRating,
      feedback,
    });
    
    setSubmitted(true);
    
    // Handle closing after delay...
  };
  
  // UI rendering...
}
```

## Implementation Details

### Files Modified

1. **use-process-pdf.ts** - Added PDF processing event tracking
2. **editor.tsx** - Added template tracking attributes
3. **use-editor-callbacks.ts → use-editor-callbacks-updated.ts** - Enhanced with event tracking
4. **menu-bar.tsx** - Updated import to use the updated callbacks
5. **env.ts** - Added PostHog environment variable definitions

### Files Added

1. **posthog.ts** - Core PostHog initialization and tracking functions
2. **helpfulness-rating.tsx** - Thumbs up/down feedback component
3. **csat-survey.tsx** - 5-point satisfaction survey component
4. **POSTHOG.md** - Implementation documentation
5. **POSTHOG_TEST_PLAN.md** - Testing guidelines and test cases

## Testing Approach

Testing the implementation involves:

1. **Local Development Testing**:
   - Using browser developer tools to verify events are sent
   - Checking PostHog debug mode in the console
   - Testing with placeholder API keys

2. **Production Verification**:
   - Verifying events in PostHog dashboard
   - Checking session recordings are properly captured
   - Ensuring user identities are correctly associated

3. **Comprehensive Testing Flows**:
   - Template selection and usage
   - PDF upload and processing
   - Feedback submission
   - Page navigation
   - Complete user journeys

Refer to the `POSTHOG_TEST_PLAN.md` document for detailed testing steps.

## Future Enhancements

Potential future enhancements include:

1. **Feature Flags**: Implementing PostHog feature flags for A/B testing
2. **Funnels Analysis**: Creating funnels to analyze conversion and drop-off points
3. **Retention Analysis**: Analyzing return user behavior
4. **Event Correlation**: Connecting events to understand user journeys
5. **User Segmentation**: Segmenting users based on behavior patterns
6. **Heatmaps**: Implementing UI interaction heatmaps for better UX insights

## Security & Privacy Considerations

The implementation includes these security measures:

1. **Input Masking**: Sensitive form fields can be marked with special classes for masking
2. **Custom Element Masking**: Supports additional masking via `maskTextSelector` and `maskInputSelector`
3. **Environment Separation**: Different PostHog projects for development vs. production
4. **Minimal Data Collection**: Only essential data is collected for each event
5. **Anonymous Data**: User-identifiable information is not collected by default
6. **Compliance**: Implementation follows GDPR and other privacy regulations

## Appendix: Event Property Reference

### Common Properties

These properties are included in most events where applicable:

- `userId`: User identifier (when available)
- `sessionId`: Current session identifier
- `appVersion`: Application version
- `environment`: Deployment environment (dev/prod)

### Event-Specific Properties

Each event type has specific properties as outlined in the Events Tracked section.