# PostHog Implementation

This repository includes implementations for PostHog analytics in the FloNotes application.

## Key Components

1. **Core Analytics:**
   - Page view tracking
   - Template usage analytics
   - FloNote creation tracking
   - Session recordings

2. **User Feedback:**
   - Helpfulness ratings (thumbs up/down)
   - CSAT survey (5-point satisfaction rating)

## Testing

The `POSTHOG_TEST_PLAN.md` document contains detailed test cases to verify all analytics integrations.

## Setup

### 1. Install Dependencies

```bash
cd vibes/apps/flonotes
npm install
```

### 2. Configure Environment Variables

Create a `.env.local` file in the app directory:

```
VITE_POSTHOG_API_KEY=<your_posthog_api_key>
VITE_POSTHOG_HOST=https://app.posthog.com
VITE_POSTHOG_DEBUG=true  # Set to false in production
```

### 3. Run Local Development Server

```bash
npm run dev
```

## Deployment

The deployment scripts (`deploy-local.sh` and `deploy-aws.sh`) have been updated to include PostHog configuration. 

For production:
```bash
./deploy-aws.sh <sso_profile> <bucket_name> <noggin_host_url>
```

For local testing:
```bash
./deploy-local.sh
```

## Documentation

- `POSTHOG.md` - Detailed implementation documentation
- `POSTHOG_TEST_PLAN.md` - Testing guidelines and test cases
- `POSTHOG_IMPLEMENTATION_SUMMARY.md` - Summary of implemented changes
- `posthog_implementation.patch` - Complete patch file with all changes

## Events Tracked

| Event | Description | Key Properties |
|-------|-------------|---------------|
| `$pageview` | Page visits | path, url |
| `template_reuse` | Template selection | template_name, pdf_count |
| `query_run_without_template` | Custom queries | has_pdfs, pdf_count |
| `flonote_created` | FloNote creation | template_name, pdf_count |
| `flonote_pdf_added` | PDF processing | pdf_uid, extract_count |
| `message_feedback` | Helpfulness ratings | message_id, rating |
| `csat_rating` | Satisfaction survey | session_id, rating |

## Components

- `posthog.ts` - Core initialization and tracking
- `helpfulness-rating.tsx` - Thumbs up/down UI
- `csat-survey.tsx` - 5-point rating UI
- `use-editor-callbacks-updated.ts` - Editor with PostHog tracking

## Resources

- [PostHog Documentation](https://posthog.com/docs)
- [PostHog React Integration](https://posthog.com/docs/libraries/react)
- [PostHog Event Tracking](https://posthog.com/docs/product-analytics/events)
- [PostHog Session Recording](https://posthog.com/docs/session-replay)