# PostHog Implementation Patch

This patch contains all changes needed to implement PostHog analytics in the FloNotes application.

## 1. Environment Configuration (env.ts)

```diff
@@ -1,11 +1,20 @@
 import { z } from "zod";

+/**
+ * Environment variable schema using Zod for validation
+ */
 const envSchema = z.object({
+  // Required environment variables
   VITE_NOGGIN_HOST: z.string().url(),
+  
+  // PostHog settings (optional with defaults)
+  VITE_POSTHOG_API_KEY: z.string().optional(),
+  VITE_POSTHOG_HOST: z.string().url().optional().default("https://app.posthog.com"),
+  VITE_POSTHOG_DEBUG: z.string().optional().transform(val => val === "true"),
 });

-// 🚨 This will only run time validate, but not at build time.
-// Needs more work to make it do that, one attempt is writing
-// your own Vite plugin.
+// Validate environment variables at runtime
 export const env = envSchema.parse(import.meta.env);
+
+// Helper to check if PostHog is enabled
+export const isPostHogEnabled = () => !!env.VITE_POSTHOG_API_KEY;
```

## 2. PostHog Core Module (posthog.ts)

```diff
@@ -0,0 +1,71 @@
+import posthog from 'posthog-js';
+import { useEffect } from 'react';
+
+/**
+ * Initialize PostHog for analytics tracking
+ * This function should be called once at app startup
+ */
+export function initPostHog() {
+  const apiKey = import.meta.env.VITE_POSTHOG_API_KEY;
+  const host = import.meta.env.VITE_POSTHOG_HOST || 'https://app.posthog.com';
+  const debug = import.meta.env.VITE_POSTHOG_DEBUG === 'true';
+
+  // Only initialize if API key is provided
+  if (apiKey) {
+    posthog.init(apiKey, {
+      api_host: host,
+      capture_pageview: false, // We'll handle this with usePageTracking
+      autocapture: false, // Disable autocapture for more control
+      capture_pageleave: true,
+      session_recording: {
+        // Enable session recordings
+        maskAllInputs: false, // Don't mask inputs
+        maskTextSelector: '.ph-no-capture',
+        maskInputSelector: '.ph-mask',
+      },
+      // Identity verification config would go here for production
+      loaded: (ph) => {
+        if (debug) {
+          ph.debug();
+          console.log('PostHog initialized:', ph);
+        }
+      },
+    });
+  } else if (debug) {
+    console.warn('PostHog API key not provided. Analytics will not be captured.');
+  }
+}
+
+/**
+ * Track a custom event in PostHog
+ * @param eventName The name of the event to track
+ * @param properties Optional properties to include with the event
+ */
+export function trackEvent(eventName: string, properties?: Record<string, any>) {
+  if (import.meta.env.VITE_POSTHOG_API_KEY) {
+    posthog.capture(eventName, properties);
+  }
+}
+
+/**
+ * Identify a user in PostHog
+ * @param userId Unique identifier for the user
+ * @param properties Optional properties to associate with the user
+ */
+export function identifyUser(userId: string, properties?: Record<string, any>) {
+  if (import.meta.env.VITE_POSTHOG_API_KEY) {
+    posthog.identify(userId, properties);
+  }
+}
+
+/**
+ * Reset the current user identity (for logout)
+ */
+export function resetUser() {
+  if (import.meta.env.VITE_POSTHOG_API_KEY) {
+    posthog.reset();
+  }
+}
+
+/**
+ * Hook for tracking page views
+ * @param currentPath The current route path
+ */
+export function usePageTracking(currentPath: string) {
+  useEffect(() => {
+    // Track page view when path changes
+    if (import.meta.env.VITE_POSTHOG_API_KEY) {
+      posthog.capture('$pageview', {
+        path: currentPath,
+        url: window.location.href,
+      });
+    }
+  }, [currentPath]);
+}
+
+/**
+ * Set or update user properties (super properties)
+ * @param properties Properties to associate with the user
+ */
+export function setUserProperties(properties: Record<string, any>) {
+  if (import.meta.env.VITE_POSTHOG_API_KEY) {
+    posthog.register(properties);
+  }
+}
```

## 3. Application Entry Point (main.tsx)

```diff
@@ -1,19 +1,27 @@
 import { RouterProvider } from "@tanstack/react-router";
-import React from "react";
+import React, { useEffect } from "react";
 import ReactDOM from "react-dom/client";
 import "./index.css";
 
 import { createRouter } from "./router";
+import { initPostHog } from "./posthog";
+
+// Initialize PostHog
+initPostHog();
 
 // Set up a Router instance
 const router = createRouter();
 
+const App = () => {
+  return (
+    <React.StrictMode>
+      <RouterProvider router={router} />
+    </React.StrictMode>
+  );
+};
+
 const rootElement = document.getElementById("app")!;
 if (!rootElement.innerHTML) {
   const root = ReactDOM.createRoot(rootElement);
-  root.render(
-    <React.StrictMode>
-      <RouterProvider router={router} />
-    </React.StrictMode>,
-  );
-}
+  root.render(<App />);
+}
```

## 4. Router with Page Tracking (router.tsx)

```diff
@@ -1,27 +1,55 @@
 import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
 import { createRouter as createTanStackRouter } from "@tanstack/react-router";
+import { useEffect } from "react";
 import { routeTree } from "./routeTree.gen";
+import { usePageTracking } from "./posthog";
 
 export const queryClient = new QueryClient();
 
+// PostHog page tracking wrapper component
+const PostHogTracker = ({ children }: { children: React.ReactNode }) => {
+  // Get current route from Tanstack Router
+  const path = window.location.pathname;
+
+  // Track page views with PostHog
+  usePageTracking(path);
+
+  // Listen for route changes
+  useEffect(() => {
+    const handleRouteChange = () => {
+      const newPath = window.location.pathname;
+      usePageTracking(newPath);
+    };
+
+    window.addEventListener('popstate', handleRouteChange);
+    return () => {
+      window.removeEventListener('popstate', handleRouteChange);
+    };
+  }, []);
+
+  return <>{children}</>;
+};
+
 // Set up a Router instance
 export function createRouter() {
   const router = createTanStackRouter({
     routeTree,
     defaultPreload: "intent",
     defaultPendingComponent: () => (
       <div className={`p-2 text-2xl`}>loading...</div>
     ),
     Wrap: ({ children }) => (
-      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
+      <QueryClientProvider client={queryClient}>
+        <PostHogTracker>{children}</PostHogTracker>
+      </QueryClientProvider>
     ),
   });
 
   return router;
 }
 
 declare module "@tanstack/react-router" {
   interface Register {
     router: ReturnType<typeof createRouter>;
   }
-}
+}
```

## 5. Helpfulness Rating Component (components/feedback/helpfulness-rating.tsx)

```diff
@@ -0,0 +1,117 @@
+import { useState } from 'react';
+import { trackEvent } from '../../posthog';
+
+interface HelpfulnessRatingProps {
+  messageId: string;
+  query: string;
+  response: string;
+}
+
+/**
+ * A thumbs up/down component that allows users to rate the helpfulness of an AI response
+ * Sends the rating, query, and response to PostHog for analytics
+ */
+export function HelpfulnessRating({ messageId, query, response }: HelpfulnessRatingProps) {
+  const [rating, setRating] = useState<'helpful' | 'unhelpful' | null>(null);
+  const [loading, setLoading] = useState(false);
+
+  const handleRating = async (isHelpful: boolean) => {
+    setLoading(true);
+    
+    try {
+      const newRating = isHelpful ? 'helpful' : 'unhelpful';
+      setRating(newRating);
+      
+      // Track the feedback event in PostHog
+      trackEvent('message_feedback', {
+        message_id: messageId,
+        rating: newRating,
+        query,
+        response_length: response.length,
+      });
+    } catch (error) {
+      console.error('Error tracking feedback:', error);
+    } finally {
+      setLoading(false);
+    }
+  };
+
+  return (
+    <div className="flex items-center gap-2 mt-4">
+      <p className="text-sm text-gray-600 mr-2">
+        {rating === null ? 'Was this response helpful?' : 'Thanks for your feedback!'}
+      </p>
+      
+      {rating === null && (
+        <>
+          <button
+            className="rounded-full p-2 hover:bg-green-100 hover:text-green-800"
+            onClick={() => handleRating(true)}
+            disabled={loading}
+            aria-label="Thumbs Up"
+          >
+            <ThumbsUpIcon className="w-4 h-4" />
+          </button>
+          
+          <button
+            className="rounded-full p-2 hover:bg-red-100 hover:text-red-800"
+            onClick={() => handleRating(false)}
+            disabled={loading}
+            aria-label="Thumbs Down"
+          >
+            <ThumbsDownIcon className="w-4 h-4" />
+          </button>
+        </>
+      )}
+      
+      {rating === 'helpful' && (
+        <span className="text-green-600">
+          <ThumbsUpIcon className="w-4 h-4" />
+        </span>
+      )}
+      
+      {rating === 'unhelpful' && (
+        <span className="text-red-600">
+          <ThumbsDownIcon className="w-4 h-4" />
+        </span>
+      )}
+    </div>
+  );
+}
+
+// Simple thumbs up/down icons
+function ThumbsUpIcon({ className = "w-6 h-6" }) {
+  return (
+    <svg 
+      xmlns="http://www.w3.org/2000/svg" 
+      viewBox="0 0 24 24" 
+      fill="none" 
+      stroke="currentColor" 
+      strokeWidth="2" 
+      strokeLinecap="round" 
+      strokeLinejoin="round" 
+      className={className}
+    >
+      <path d="M7 10v12" />
+      <path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2h0a3.13 3.13 0 0 1 3 3.88Z" />
+    </svg>
+  );
+}
+
+function ThumbsDownIcon({ className = "w-6 h-6" }) {
+  return (
+    <svg 
+      xmlns="http://www.w3.org/2000/svg" 
+      viewBox="0 0 24 24" 
+      fill="none" 
+      stroke="currentColor" 
+      strokeWidth="2" 
+      strokeLinecap="round" 
+      strokeLinejoin="round" 
+      className={className}
+    >
+      <path d="M17 14V2" />
+      <path d="M9 18.12 10 14H4.17a2 2 0 0 1-1.92-2.56l2.33-8A2 2 0 0 1 6.5 2H20a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2h-2.76a2 2 0 0 0-1.79 1.11L12 22h0a3.13 3.13 0 0 1-3-3.88Z" />
+    </svg>
+  );
+}
```

## 6. CSAT Survey Component (components/feedback/csat-survey.tsx)

```diff
@@ -0,0 +1,99 @@
+import { useState } from 'react';
+import { trackEvent } from '../../posthog';
+
+interface CSATSurveyProps {
+  sessionId: string;
+  onClose?: () => void;
+}
+
+/**
+ * A Customer Satisfaction (CSAT) survey component with a 5-point rating scale
+ * Tracks user satisfaction with PostHog events
+ */
+export function CSATSurvey({ sessionId, onClose }: CSATSurveyProps) {
+  const [selectedRating, setSelectedRating] = useState<number | null>(null);
+  const [submitted, setSubmitted] = useState(false);
+  const [feedback, setFeedback] = useState('');
+
+  const handleRatingSelect = (rating: number) => {
+    setSelectedRating(rating);
+  };
+
+  const handleSubmit = () => {
+    if (selectedRating === null) return;
+    
+    // Track the CSAT event in PostHog
+    trackEvent('csat_rating', {
+      session_id: sessionId,
+      rating: selectedRating,
+      feedback: feedback,
+    });
+    
+    setSubmitted(true);
+    
+    // Call onClose after a delay if provided
+    if (onClose) {
+      setTimeout(onClose, 2000);
+    }
+  };
+
+  if (submitted) {
+    return (
+      <div className="bg-white p-4 rounded-lg shadow border border-gray-200 max-w-md">
+        <h3 className="font-medium text-lg mb-2">Thank you for your feedback!</h3>
+        <p className="text-gray-600 text-sm">Your feedback helps us improve our service.</p>
+      </div>
+    );
+  }
+
+  return (
+    <div className="bg-white p-4 rounded-lg shadow border border-gray-200 max-w-md">
+      <h3 className="font-medium text-lg mb-2">How would you rate your experience?</h3>
+      
+      <div className="flex justify-between mb-4 py-2">
+        {[1, 2, 3, 4, 5].map((rating) => (
+          <button
+            key={rating}
+            className={`flex flex-col items-center justify-center w-12 h-12 rounded-full
+              ${selectedRating === rating 
+                ? 'bg-anterior-500 text-white' 
+                : 'bg-gray-100 hover:bg-gray-200 text-gray-700'}`}
+            onClick={() => handleRatingSelect(rating)}
+            aria-label={`Rating ${rating}`}
+          >
+            <span className="text-lg font-medium">{rating}</span>
+          </button>
+        ))}
+      </div>
+      
+      <div className="flex flex-col gap-2 mb-4">
+        <label className="text-sm text-gray-600">Any additional feedback?</label>
+        <textarea 
+          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-anterior-500"
+          rows={3}
+          placeholder="Tell us more about your experience..."
+          value={feedback}
+          onChange={(e) => setFeedback(e.target.value)}
+        />
+      </div>
+
+      <div className="flex justify-end">
+        <button
+          className={`px-4 py-2 rounded-md 
+            ${selectedRating === null 
+              ? 'bg-gray-300 text-gray-500 cursor-not-allowed' 
+              : 'bg-anterior-500 text-white hover:bg-anterior-600'}`}
+          onClick={handleSubmit}
+          disabled={selectedRating === null}
+        >
+          Submit Feedback
+        </button>
+      </div>
+      
+      <div className="flex justify-between mt-2">
+        <span className="text-sm text-gray-500">Very dissatisfied</span>
+        <span className="text-sm text-gray-500">Very satisfied</span>
+      </div>
+    </div>
+  );
+}
```

## 7. PDF Process Tracking (hooks/use-process-pdf.ts)

```diff
@@ -1,6 +1,7 @@
 import { useMutation } from "@tanstack/react-query";
 import { savePdf, updatePdfExtracts } from "./use-pdf-storage";
 import { processAndGetPdfExtracts } from "../services/noggin-api";
+import { trackEvent } from "../posthog";
 
 export const processPdfsMutationKey = [["pdf", "processPdfs"]];
 
@@ -73,6 +74,14 @@ export function useProcessPdfs() {
           data.stemUid,
           data.pdfUid,
         );
+        
+        // Track PDF processing in PostHog
+        trackEvent('flonote_pdf_added', {
+          pdf_uid: data.pdfUid,
+          stem_uid: data.stemUid,
+          extract_count: data.result.extracts?.length || 0,
+        });
       }
     },
```

## 8. Template Tracking in Editor (components/shell/notes/editor.tsx)

```diff
@@ -52,7 +52,10 @@ const Tiptap = () => {
   const setTemplateContent = (templateKey: keyof typeof templates) => {
     const template = templates[templateKey];
     if (template) {
-      setContent(template.content);
+      // Add data-template-id attribute to the content for tracking purposes
+      const contentWithTemplateId = template.content.replace('<h1>', `<h1 data-template-id="${templateKey}">`); 
+      setContent(contentWithTemplateId);
     }
   };
```

## 9. Editor Callbacks with Tracking (components/shell/notes/hooks/use-editor-callbacks-updated.ts)

This file is a copy of use-editor-callbacks.ts with added tracking.

```diff
@@ -0,0 +1,265 @@
+import { Editor } from "@tiptap/react";
+import { useCallback } from "react";
+import { replaceInsertInfoSpans } from "../utils/editor-utils";
+import { db } from "../../../../indexed-db/db";
+import { useLiveQuery } from "dexie-react-hooks";
+import { useMutation } from "@tanstack/react-query";
+import { createAndWaitForNote } from "../../../../services/noggin-api";
+import { trackEvent } from "../../../../posthog";
+
+/**
+ * Sanitizes HTML responses from the LLM to ensure they're compatible with TipTap
+ *
+ * This handles different formats of HTML that might be returned and extracts
+ * the relevant content for insertion into the editor.
+ */
+const sanitizeHtml = (html: string): string => {
+  // Skip sanitization if html is not a string
+  if (typeof html !== "string") {
+    console.error("Invalid HTML received:", html);
+    return "<p>Error: Invalid response from LLM service</p>";
+  }
+
+  // Sometimes the API returns HTML without proper document structure
+  // Ensure we have proper HTML structure
+  if (!html.includes("<html>") && !html.includes("<!DOCTYPE")) {
+    // If we just have fragments, wrap them properly
+    if (!html.includes("<body>")) {
+      // This appears to be just HTML fragments, not a complete document
+      return html;
+    }
+  }
+
+  // If we got a full HTML document, extract just the body content
+  const bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
+  if (bodyMatch && bodyMatch[1]) {
+    return bodyMatch[1].trim();
+  }
+
+  return html;
+};
+
+export const useEditorCallbacks = (editor: Editor | null) => {
+  // Always use direct API calls with React Query
+  // This ensures we're using real hooks within the component
+  const noteMutation = useMutation({
+    // Use the updated function that handles polling automatically
+    mutationKey: ["llm.notes"],
+    mutationFn: createAndWaitForNote,
+  });
+
+  const pdfs =
+    useLiveQuery(() =>
+      db.pdfs.where("documentType").equals("clinical").toArray(),
+    ) ?? [];
+
+  const handleRunAutoFill = useCallback(async () => {
+    if (!editor) return;
+    const currentContent = editor.getHTML();
+    console.log("Current content before extraction:", currentContent);
+    const extractedContent = replaceInsertInfoSpans(currentContent);
+    console.log(
+      "Extracted content with replaced QuickFill tags:",
+      extractedContent,
+    );
+
+    // Check if this is a template run by looking for template markers in the HTML
+    const isTemplateRun = currentContent.includes('data-template-id=');
+    let templateName = "custom";
+    
+    // Extract template name if it's a template run
+    if (isTemplateRun) {
+      const templateMatch = currentContent.match(/data-template-id="([^"]+)"/);
+      if (templateMatch && templateMatch[1]) {
+        templateName = templateMatch[1];
+      }
+    }
+
+    // Track the event in PostHog
+    if (isTemplateRun) {
+      trackEvent('template_reuse', {
+        template_name: templateName,
+        has_pdfs: pdfs.length > 0,
+        pdf_count: pdfs.length,
+      });
+    } else {
+      trackEvent('query_run_without_template', {
+        has_pdfs: pdfs.length > 0,
+        pdf_count: pdfs.length,
+      });
+    }
+
+    const extractsArray =
+      pdfs
+        .filter((pdf) => pdf && pdf.extracts)
+        .map((pdf) => {
+          return {
+            id: pdf.id.toString(),
+            extracts: pdf.extracts.result.extracts || [],
+          };
+        }) || [];
+
+    // Find the first PDF that has a stemUid from the server
+    const pdfWithStemUid = pdfs.find((pdf) => pdf.stemUid);
+
+    // Check if we have a server-provided stemUid
+    if (!pdfWithStemUid?.stemUid) {
+      console.error(
+        "No stemUid found in PDFs. Cannot create note without a server-assigned stemUid.",
+      );
+      alert(
+        "Error: Cannot create note without processing a PDF first. Please upload a PDF document.",
+      );
+      return;
+    }
+
+    const stemUid = pdfWithStemUid.stemUid;
+    console.log(
+      `Using server-assigned stemUid ${stemUid} from PDF for note creation`,
+    );
+
+    try {
+      console.log(
+        "Sending request to LLM with clinicals:",
+        extractsArray.length,
+        "stemUid:",
+        stemUid,
+      );
+
+      // This now handles the complete flow including polling
+      const noteContent = await noteMutation.mutateAsync({
+        stemUid,
+        clinicals: extractsArray,
+        messages: [],
+        userMessage: `Write a clinical note by:
+1. Using the following template structure: ${extractedContent}
+2. Replace each {{QuickFill}} placeholder with ONLY the specific information being requested based on context
+3. Each {{QuickFill}} replacement should be brief and focused only on what is asked for in the preceding label
+4. Maintain the exact HTML structure and formatting, unless the {{QuickFill}} replacement calls for an ordered or unordered list (<ol> or <ul>) with list items (<li>)
+5. For EACH piece of information, include a citation tag immediately after the text
+6. Format dates as MM/DD/YYYY
+7. Use consistent medical terminology following [specify standard, e.g. SNOMED CT]
+8. For missing or unclear data, write "[Not documented]"
+9. Flag any critical values with <critical></critical> tags
+10. Validate all numbers are within typical clinical ranges
+11. DO NOT include the entire content of the source - only extract the relevant information
+12. Keep your answers SPECIFIC and CONCISE for each field
+13. Checkbox should be filled in if the information is present from [] to [x], including a citation tag.
+14. Citation tags should exist within a <li> tag if the citation is relevant to a list item.
+
+Citation format:
+- Use <citation fileId="X" extractId="Y" blockIds="Z" /> tags after each piece of information
+- Each {{QuickFill}} should be replaced by ONLY the requested data with appropriate citation(s)
+- Include page numbers in the citation when available
+
+Example input:
+<p><strong>Address:</strong> {{QuickFill}}</p>
+
+Example output with exactly one citation:
+<p><strong>Address:</strong> 123 TOON AVENUE, TOONTOWN, 12345, ARIZONA <citation fileId="1" extractId="abc123" blockIds="1" /></p>
+
+Example input:
+<p><strong>Date of Birth:</strong> {{QuickFill}}</p>
+
+Example output with exactly two citations:
+<p><strong>Date of Birth:</strong> 03/12/1962 <citation fileId="1" extractId="def456" blockIds="1,2" /></p>
+
+Example input:
+<p><strong>ICD-10 Codes:</strong> {{QuickFill}}</p>
+
+Example output with ordered one citation and ordered list of values:
+<p>
+    All ICD-10 Codes: C23 <citation extractid="E1" fileid="1" blockids="7"></citation>
+    <ol>
+        <li>ICD 10 diagnoses: Malignant neoplasm of gallbladder (C23)</li>
+        <li>Unspecified asthma, uncomplicated (J45.909)</li>
+        <li>Type 2 diabetes mellitus without complications (E11.9)</li>
+        <li>Essential (primary) hypertension (I10)</li>
+        <li>Depression, unspecified (F32.A)</li>
+        <li>Bilateral primary osteoarthritis of hip (M16.0)</li>
+        <li>Hypothyroidism, unspecified (E03.9)</li>
+        <li>History of falling (Z91.81)</li>
+        <li>Long term (current) use of insulin (Z79.4)</li>
+        <li>Acquired absence of kidney (Z90.5)</li>
+    </ol>
+</p>
+
+Invalid outputs:
+- Adding extra HTML elements, unless the {{QuickFill}} replacement calls for an ordered or unordered list (<ol> or <ul>) with list items (<li>)
+- Changing template structure
+- Omitting citations
+- Free-form text outside template
+- Including information not specifically requested by the field label
+- Returning entire sections or paragraphs when only a specific data point is asked for`,
+      });
+
+      console.log(
+        "Received completed note content from LLM:",
+        typeof noteContent === "string"
+          ? noteContent.substring(0, 100) + "..."
+          : noteContent,
+      );
+
+      // Track FloNote creation event in PostHog
+      trackEvent('flonote_created', {
+        template_name: templateName,
+        has_pdfs: pdfs.length > 0,
+        pdf_count: pdfs.length,
+        has_template: isTemplateRun,
+      });
+
+      // Clean up the HTML - now we know we have a string from createAndWaitForNote
+      const cleanedHtml = sanitizeHtml(noteContent);
+      console.log("Cleaned HTML:", cleanedHtml.substring(0, 100) + "...");
+
+      // Force a complete content replacement
+      editor.commands.clearContent();
+      setTimeout(() => {
+        console.log("Setting editor content with cleaned response");
+        editor.commands.setContent(cleanedHtml);
+
+        // Validate content was set
+        setTimeout(() => {
+          const newContent = editor.getHTML();
+          console.log(
+            "New editor content after update:",
+            newContent.substring(0, 100) +
+              (newContent.length > 100 ? "..." : ""),
+          );
+
+          if (newContent.trim() === "" || newContent === "<p></p>") {
+            console.error(
+              "Editor content is still empty after update, falling back to direct HTML insertion",
+            );
+            // As a fallback, try a different approach to insert content
+            editor.commands.insertContent(cleanedHtml);
+          }
+        }, 100);
+      }, 100);
+    } catch (error) {
+      console.error("Error in handleRunAutoFill:", error);
+      // Show an error message to the user
+      alert(
+        `Error generating note: ${error instanceof Error ? error.message : "Unknown error"}`,
+      );
+    }
+  }, [editor, noteMutation, pdfs]);
```

## 10. Update Menu Bar to Use New Callbacks (components/shell/notes/components/menu/menu-bar.tsx)

```diff
@@ -12,7 +12,7 @@ import {
   DropdownMenuTrigger,
   DropdownMenuGroup,
 } from "../../../../../../neuron/react";
-import { useEditorCallbacks } from "../../hooks/use-editor-callbacks";
+import { useEditorCallbacks } from "../../hooks/use-editor-callbacks-updated";
 import { LoadingSpinner } from "../loading-spinner";
 
 interface MenuBarProps {
```

## 11. Update package.json to Add PostHog Dependency

```diff
@@ -54,6 +54,7 @@
     "framer-motion": "^12.0.6",
     "lodash": "^4.17.21",
+    "posthog-js": "^1.114.0",
     "react": "^18.3.1",
     "react-aria": "^3.37.0",
     "react-dom": "^18.3.1",
```

## 12. Deploy Script Updates (deploy-local.sh)

```diff
@@ -26,10 +27,16 @@ LOCALSTACK_ACCESS_KEY="000000000000"
 LOCALSTACK_SECRET_KEY="local-stack-accepts-anything-here"
 VITE_NOGGIN_HOST="http://localhost:20701"
 
+# PostHog configuration for local development
+VITE_POSTHOG_API_KEY="${VITE_POSTHOG_API_KEY:-ph_test_key_placeholder}"
+VITE_POSTHOG_HOST="${VITE_POSTHOG_HOST:-https://app.posthog.com}"
+VITE_POSTHOG_DEBUG="true"
+
 echo "Local deployment selected with Localstack endpoint: $LOCALSTACK_ENDPOINT"
 echo "Using VITE_NOGGIN_HOST: $VITE_NOGGIN_HOST"
+echo "Using PostHog settings:"
+echo "  VITE_POSTHOG_API_KEY: ${VITE_POSTHOG_API_KEY:0:5}... (truncated)"
+echo "  VITE_POSTHOG_HOST: $VITE_POSTHOG_HOST"
+echo "  VITE_POSTHOG_DEBUG: $VITE_POSTHOG_DEBUG"
 
 # ... More content follows ...
@@ -75,8 +82,14 @@ build_app() {
     # clean up the LOCAL build directory first
     echo "Cleaning previous build artifacts..."
     rm -rf dist node_modules/.vite
-
+    
+    # Export environment variables for the build
     export VITE_NOGGIN_HOST="${VITE_NOGGIN_HOST}"
+    export BASE_PATH="${BASE_PATH}"
+    
+    # PostHog environment variables
+    export VITE_POSTHOG_API_KEY="${VITE_POSTHOG_API_KEY}"
+    export VITE_POSTHOG_HOST="${VITE_POSTHOG_HOST}"
+    export VITE_POSTHOG_DEBUG="${VITE_POSTHOG_DEBUG}"
```

## 13. Deploy Script Updates (deploy-aws.sh)

```diff
@@ -27,12 +27,21 @@ SSO_PROFILE="${1:-}" # TODO: add readme for getting an aws sso profile set up on
 BUCKET_NAME="${2:-}" # e.g. anterior-pr-3055-platform, even anterior-master-platform at some point
 VITE_NOGGIN_HOST="${3:-}" # e.g. https://labs-pr-3055-luhhr.anterior.app, https://labs.anterior.app at some point
 
+# PostHog configuration for production deployment
+VITE_POSTHOG_API_KEY="${VITE_POSTHOG_API_KEY:-ph_prod_key_placeholder}"
+VITE_POSTHOG_HOST="${VITE_POSTHOG_HOST:-https://app.posthog.com}"
+# Disable debug mode for production
+VITE_POSTHOG_DEBUG="false"
+
 if [ -z "$SSO_PROFILE" ] || [ -z "$BUCKET_NAME" ] || [ -z "$VITE_NOGGIN_HOST" ]; then
     echo "Error: Missing required parameters for AWS deployment"
     echo "Usage: ./deploy-aws.sh [sso_profile] [bucket_name] [noggin_host_url]"
     exit 1
 fi
 
 echo "AWS deployment selected with bucket: $BUCKET_NAME"
+echo "Using PostHog settings:"
+echo "  VITE_POSTHOG_API_KEY: ${VITE_POSTHOG_API_KEY:0:5}... (truncated)"
+echo "  VITE_POSTHOG_HOST: $VITE_POSTHOG_HOST"
+echo "  VITE_POSTHOG_DEBUG: $VITE_POSTHOG_DEBUG"
 
 # ... More content follows ...
@@ -68,8 +77,13 @@ build_app() {
     echo "Cleaning previous build artifacts..."
     rm -rf dist node_modules/.vite
 
-    # Set environment variables for the build
+    # Export environment variables for the build
     export VITE_NOGGIN_HOST="${VITE_NOGGIN_HOST}"
+    export BASE_PATH="${BASE_PATH}"
+    
+    # PostHog environment variables
+    export VITE_POSTHOG_API_KEY="${VITE_POSTHOG_API_KEY}"
+    export VITE_POSTHOG_HOST="${VITE_POSTHOG_HOST}"
+    export VITE_POSTHOG_DEBUG="${VITE_POSTHOG_DEBUG}"
```