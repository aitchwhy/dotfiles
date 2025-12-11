/**
 * OpenTelemetry instrumentation for Datadog.
 * MUST be imported FIRST in server.ts.
 */

import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-proto';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-proto';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-node';
import { resourceFromAttributes } from '@opentelemetry/resources';
import {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
  ATTR_DEPLOYMENT_ENVIRONMENT,
} from '@opentelemetry/semantic-conventions';

const isProduction = process.env.NODE_ENV === 'production';
const serviceName = process.env.DD_SERVICE || 'PROJECT_NAME';
const serviceVersion = process.env.DD_VERSION || '0.0.0';
const environment = process.env.DD_ENV || 'development';
const otlpEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318';

const resource = resourceFromAttributes({
  [ATTR_SERVICE_NAME]: serviceName,
  [ATTR_SERVICE_VERSION]: serviceVersion,
  [ATTR_DEPLOYMENT_ENVIRONMENT]: environment,
  'dd.service': serviceName,
  'dd.version': serviceVersion,
  'dd.env': environment,
});

const sdk = new NodeSDK({
  resource,
  spanProcessors: [
    new BatchSpanProcessor(
      new OTLPTraceExporter({ url: `${otlpEndpoint}/v1/traces` }),
      { maxQueueSize: 2048, scheduledDelayMillis: isProduction ? 5000 : 1000 }
    ),
  ],
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({ url: `${otlpEndpoint}/v1/metrics` }),
    exportIntervalMillis: isProduction ? 60000 : 10000,
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': { enabled: false },
      '@opentelemetry/instrumentation-http': {
        ignoreIncomingRequestHook: (req) => req.url === '/health',
      },
    }),
  ],
});

sdk.start();
console.log(`[OTEL] Initialized: service=${serviceName} env=${environment}`);

process.on('SIGTERM', async () => {
  await sdk.shutdown();
  process.exit(0);
});

export { sdk };
