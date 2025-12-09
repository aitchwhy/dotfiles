/**
 * Version Policy
 *
 * Enforces version constraints from the Signet stack definition.
 * Run at deploy time to catch version drift before provisioning.
 */
import {
  PolicyPack,
  validateResourceOfType,
} from '@pulumi/policy';
import * as gcp from '@pulumi/gcp';
import { STACK } from '../versions';

// =============================================================================
// POLICY CONFIGURATION
// =============================================================================

/** Approved PostgreSQL versions */
const APPROVED_POSTGRES_VERSIONS = [
  'POSTGRES_14',
  'POSTGRES_15',
  'POSTGRES_16',
] as const;

/** Minimum Cloud Run memory in MB */
const MIN_CLOUD_RUN_MEMORY_MB = 256;

/** Maximum Cloud Run memory in MB */
const MAX_CLOUD_RUN_MEMORY_MB = 8192;

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/**
 * Parse memory string to MB
 * e.g., "512Mi" -> 512, "2Gi" -> 2048
 */
function parseMemoryToMb(memory: string): number {
  const match = memory.match(/^(\d+)(Mi|Gi)$/);
  if (!match) return 0;

  const [, value, unit] = match;
  if (!value) return 0;
  const num = parseInt(value, 10);
  return unit === 'Gi' ? num * 1024 : num;
}

// =============================================================================
// POLICIES
// =============================================================================

/**
 * Version Policy Pack - Enforce stack version constraints
 */
export const versionPolicies = new PolicyPack('signet-versions', {
  policies: [
    // =========================================================================
    // DATABASE POLICIES
    // =========================================================================
    {
      name: 'enforce-postgres-version',
      description: `Cloud SQL must use approved PostgreSQL version: ${APPROVED_POSTGRES_VERSIONS.join(', ')}`,
      enforcementLevel: 'mandatory',
      validateResource: validateResourceOfType(
        gcp.sql.DatabaseInstance,
        (instance, _args, reportViolation) => {
          const version = instance.databaseVersion;
          if (!APPROVED_POSTGRES_VERSIONS.includes(version as any)) {
            reportViolation(
              `PostgreSQL version "${version}" is not approved. ` +
                `Use one of: ${APPROVED_POSTGRES_VERSIONS.join(', ')}`
            );
          }
        }
      ),
    },

    {
      name: 'require-database-backups',
      description: 'Cloud SQL instances must have backups enabled',
      enforcementLevel: 'mandatory',
      validateResource: validateResourceOfType(
        gcp.sql.DatabaseInstance,
        (instance, _args, reportViolation) => {
          const backupConfig = instance.settings?.backupConfiguration;
          if (!backupConfig?.enabled) {
            reportViolation(
              'Cloud SQL instance must have backups enabled. ' +
                'Set settings.backupConfiguration.enabled = true'
            );
          }
        }
      ),
    },

    {
      name: 'require-ssl-for-database',
      description: 'Cloud SQL instances must require SSL connections',
      enforcementLevel: 'mandatory',
      validateResource: validateResourceOfType(
        gcp.sql.DatabaseInstance,
        (instance, _args, reportViolation) => {
          const ipConfig = instance.settings?.ipConfiguration;
          // Check sslMode instead of deprecated requireSsl
          if (ipConfig && !ipConfig.sslMode) {
            reportViolation(
              'Cloud SQL instance must require SSL connections. ' +
                'Set settings.ipConfiguration.requireSsl = true'
            );
          }
        }
      ),
    },

    // =========================================================================
    // CLOUD RUN POLICIES
    // =========================================================================
    {
      name: 'enforce-cloud-run-memory-limits',
      description: `Cloud Run services must have memory between ${MIN_CLOUD_RUN_MEMORY_MB}Mi and ${MAX_CLOUD_RUN_MEMORY_MB}Mi`,
      enforcementLevel: 'mandatory',
      validateResource: validateResourceOfType(
        gcp.cloudrunv2.Service,
        (service, _args, reportViolation) => {
          const containers = service.template?.containers ?? [];
          for (const container of containers) {
            const limits = container.resources?.limits as Record<string, unknown> | undefined;
            const memory = limits?.['memory'] as string | undefined;
            if (memory) {
              const memoryMb = parseMemoryToMb(memory);
              if (memoryMb < MIN_CLOUD_RUN_MEMORY_MB) {
                reportViolation(
                  `Container memory ${memory} is below minimum ${MIN_CLOUD_RUN_MEMORY_MB}Mi. ` +
                    `Increase memory allocation.`
                );
              }
              if (memoryMb > MAX_CLOUD_RUN_MEMORY_MB) {
                reportViolation(
                  `Container memory ${memory} exceeds maximum ${MAX_CLOUD_RUN_MEMORY_MB}Mi. ` +
                    `Reduce memory allocation.`
                );
              }
            }
          }
        }
      ),
    },

    {
      name: 'enforce-cloud-run-scaling',
      description: 'Cloud Run services must have max instances configured',
      enforcementLevel: 'advisory',
      validateResource: validateResourceOfType(
        gcp.cloudrunv2.Service,
        (service, _args, reportViolation) => {
          const scaling = service.template?.scaling;
          if (!scaling?.maxInstanceCount) {
            reportViolation(
              'Cloud Run service should have maxInstanceCount configured ' +
                'to prevent runaway scaling. Recommended: 10-100 based on load.'
            );
          }
        }
      ),
    },

    {
      name: 'require-health-checks',
      description: 'Cloud Run services should have health check probes',
      enforcementLevel: 'advisory',
      validateResource: validateResourceOfType(
        gcp.cloudrunv2.Service,
        (service, _args, reportViolation) => {
          const containers = service.template?.containers ?? [];
          for (const container of containers) {
            if (!container.startupProbe && !container.livenessProbe) {
              reportViolation(
                'Cloud Run container should have startup or liveness probes ' +
                  'for proper health monitoring.'
              );
            }
          }
        }
      ),
    },

    // =========================================================================
    // PUB/SUB POLICIES
    // =========================================================================
    {
      name: 'require-subscription-ack-deadline',
      description: 'Pub/Sub subscriptions must have appropriate ack deadline',
      enforcementLevel: 'advisory',
      validateResource: validateResourceOfType(
        gcp.pubsub.Subscription,
        (subscription, _args, reportViolation) => {
          const ackDeadline = subscription.ackDeadlineSeconds ?? 10;
          if (ackDeadline < 10 || ackDeadline > 600) {
            reportViolation(
              `Pub/Sub subscription ack deadline ${ackDeadline}s should be between 10-600s. ` +
                `Current value may cause message redelivery issues.`
            );
          }
        }
      ),
    },

    // =========================================================================
    // STACK VERSION POLICY
    // =========================================================================
    {
      name: 'report-stack-version',
      description: 'Report the Signet stack version being used',
      enforcementLevel: 'advisory',
      validateStack: (_args, _reportViolation) => {
        // This is informational - reports which stack version is in use
        console.log(`Signet Stack Version: ${STACK.meta.ssotVersion}`);
        console.log(`Stack Frozen: ${STACK.meta.frozen}`);
        console.log(`Stack Updated: ${STACK.meta.updated}`);
      },
    },
  ],
});

export default versionPolicies;
