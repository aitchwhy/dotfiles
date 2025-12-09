/**
 * Effect-TS Integration Policy
 *
 * Enforces patterns that support Effect-TS based applications:
 * - No hardcoded secrets (use Secret Manager)
 * - Proper error handling configuration
 * - Observability requirements
 */
import {
  PolicyPack,
  validateResourceOfType,
} from '@pulumi/policy';
import * as gcp from '@pulumi/gcp';

// =============================================================================
// POLICY CONFIGURATION
// =============================================================================

/** Patterns that indicate sensitive data */
const SENSITIVE_PATTERNS = [
  'PASSWORD',
  'SECRET',
  'TOKEN',
  'KEY',
  'CREDENTIAL',
  'API_KEY',
  'APIKEY',
  'AUTH',
  'PRIVATE',
  'SIGNING',
] as const;

/** Environment variables that are allowed to have "KEY" in name */
const ALLOWED_KEY_VARS = [
  'POSTHOG_KEY', // Analytics key (not secret)
  'PUBLIC_KEY', // Public keys are fine
] as const;

// =============================================================================
// TYPE GUARDS
// =============================================================================

/**
 * Type guard for Record<string, unknown>
 */
function isRecord(obj: unknown): obj is Record<string, unknown> {
  return typeof obj === 'object' && obj !== null;
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/**
 * Check if an environment variable name looks sensitive
 */
function isSensitiveEnvVar(name: string): boolean {
  const upperName = name.toUpperCase();

  // Check if it's in the allowed list
  if (ALLOWED_KEY_VARS.some((allowed) => upperName === allowed)) {
    return false;
  }

  // Check against sensitive patterns
  return SENSITIVE_PATTERNS.some((pattern) => upperName.includes(pattern));
}

// =============================================================================
// POLICIES
// =============================================================================

/**
 * Effect Policy Pack - Support Effect-TS patterns in infrastructure
 */
export const effectPolicies = new PolicyPack('signet-effect', {
  policies: [
    // =========================================================================
    // SECRET MANAGEMENT
    // =========================================================================
    {
      name: 'no-hardcoded-secrets',
      description: 'Sensitive environment variables must use Secret Manager, not plaintext values',
      enforcementLevel: 'mandatory',
      validateResource: validateResourceOfType(
        gcp.cloudrunv2.Service,
        (service, _args, reportViolation) => {
          const containers = service.template?.containers ?? [];

          for (const container of containers) {
            for (const env of container.envs ?? []) {
              // Check if this looks like a sensitive env var
              if (isSensitiveEnvVar(env.name)) {
                // If it has a direct value instead of valueSource, it's a violation
                if (env.value && !env.valueSource) {
                  reportViolation(
                    `Environment variable "${env.name}" appears to contain sensitive data ` +
                      `but is set as plaintext. Use Secret Manager instead:\n` +
                      `  envs: [{\n` +
                      `    name: "${env.name}",\n` +
                      `    valueSource: {\n` +
                      `      secretKeyRef: {\n` +
                      `        secret: "my-secret",\n` +
                      `        version: "latest"\n` +
                      `      }\n` +
                      `    }\n` +
                      `  }]`
                  );
                }
              }
            }
          }
        }
      ),
    },

    {
      name: 'prefer-secret-manager',
      description: 'Recommend Secret Manager for configuration that may become sensitive',
      enforcementLevel: 'advisory',
      validateResource: validateResourceOfType(
        gcp.cloudrunv2.Service,
        (service, _args, reportViolation) => {
          const containers = service.template?.containers ?? [];
          let plainTextEnvCount = 0;

          for (const container of containers) {
            for (const env of container.envs ?? []) {
              if (env.value && !env.valueSource) {
                plainTextEnvCount++;
              }
            }
          }

          if (plainTextEnvCount > 10) {
            reportViolation(
              `Service has ${plainTextEnvCount} plaintext environment variables. ` +
                `Consider using Secret Manager or ConfigMaps for better manageability.`
            );
          }
        }
      ),
    },

    // =========================================================================
    // OBSERVABILITY REQUIREMENTS
    // =========================================================================
    {
      name: 'require-logging',
      description: 'Cloud Run services should have proper logging configuration',
      enforcementLevel: 'advisory',
      validateResource: validateResourceOfType(
        gcp.cloudrunv2.Service,
        (service, _args, reportViolation) => {
          const containers = service.template?.containers ?? [];

          for (const container of containers) {
            const envNames = (container.envs ?? []).map((e) => e.name);

            // Check for common logging env vars
            const hasLoggingConfig =
              envNames.includes('LOG_LEVEL') ||
              envNames.includes('OTEL_EXPORTER_OTLP_ENDPOINT') ||
              envNames.includes('NODE_ENV');

            if (!hasLoggingConfig) {
              reportViolation(
                `Cloud Run service should have logging configuration. ` +
                  `Add LOG_LEVEL or OTEL_EXPORTER_OTLP_ENDPOINT environment variable.`
              );
            }
          }
        }
      ),
    },

    {
      name: 'recommend-opentelemetry',
      description: 'Services should include OpenTelemetry configuration for observability',
      enforcementLevel: 'advisory',
      validateResource: validateResourceOfType(
        gcp.cloudrunv2.Service,
        (service, _args, reportViolation) => {
          const containers = service.template?.containers ?? [];

          for (const container of containers) {
            const envNames = (container.envs ?? []).map((e) => e.name);

            const hasOtel = envNames.some((name) => name.startsWith('OTEL_'));

            if (!hasOtel) {
              reportViolation(
                `Consider adding OpenTelemetry configuration for distributed tracing:\n` +
                  `  OTEL_SERVICE_NAME: Service name for traces\n` +
                  `  OTEL_EXPORTER_OTLP_ENDPOINT: Collector endpoint`
              );
            }
          }
        }
      ),
    },

    // =========================================================================
    // ERROR HANDLING
    // =========================================================================
    {
      name: 'require-dead-letter-queue',
      description: 'Pub/Sub subscriptions should have dead letter configuration for error handling',
      enforcementLevel: 'advisory',
      validateResource: validateResourceOfType(
        gcp.pubsub.Subscription,
        (subscription, args, reportViolation) => {
          // Push subscriptions especially need dead letter queues
          if (subscription.pushConfig && !subscription.deadLetterPolicy) {
            reportViolation(
              `Push subscription "${args.name}" should have a dead letter policy ` +
                `for handling failed message delivery. Add deadLetterPolicy configuration.`
            );
          }
        }
      ),
    },

    {
      name: 'require-retry-policy',
      description: 'Pub/Sub subscriptions should have retry policy for resilience',
      enforcementLevel: 'advisory',
      validateResource: validateResourceOfType(
        gcp.pubsub.Subscription,
        (subscription, args, reportViolation) => {
          if (!subscription.retryPolicy) {
            reportViolation(
              `Subscription "${args.name}" should have a retry policy ` +
                `for handling transient failures. Add retryPolicy with exponential backoff.`
            );
          }
        }
      ),
    },

    // =========================================================================
    // EFFECT-TS PATTERNS
    // =========================================================================
    {
      name: 'validate-stack-version-label',
      description: 'Resources should have stack-version label for Effect-TS layer tracking',
      enforcementLevel: 'advisory',
      validateStack: (args, reportViolation) => {
        for (const resource of args.resources) {
          if (!resource.type.startsWith('gcp:')) continue;

          const props = resource.props;
          if (!isRecord(props)) continue;

          const labelsRaw = props['labels'] ?? props['userLabels'];
          const labels = isRecord(labelsRaw) ? labelsRaw : undefined;

          if (!labels || typeof labels['stack-version'] !== 'string') {
            // Only report for main resource types
            if (
              resource.type.includes('Service') ||
              resource.type.includes('Instance') ||
              resource.type.includes('Topic')
            ) {
              reportViolation(
                `Resource "${resource.name}" should have stack-version label ` +
                  `for tracking Signet stack version used in deployment.`
              );
            }
          }
        }
      },
    },
  ],
});

export default effectPolicies;
