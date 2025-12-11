#!/usr/bin/env bun
/**
 * PROJECT_NAME Server
 *
 * CRITICAL: Import instrumentation FIRST for OpenTelemetry auto-instrumentation.
 */

// MUST be first import
import './instrumentation.js';

import { Hono } from 'hono';
import { logger } from './lib/telemetry/logger.js';

const app = new Hono();

// Health check (excluded from tracing)
app.get('/health', (c) => c.json({ status: 'ok' }));

// API routes
app.get('/', (c) => {
  logger.info('Root endpoint hit');
  return c.json({ message: 'Hello from PROJECT_NAME!' });
});

const port = Number(process.env.PORT) || 3000;

logger.info('Starting server', { port });

export default {
  port,
  fetch: app.fetch,
};
