/**
 * Hexagonal Architecture Policy
 *
 * Enforces naming conventions and labeling requirements
 * that align with Signet's hexagonal architecture patterns.
 */
import { PolicyPack } from '@pulumi/policy';

// =============================================================================
// POLICY CONFIGURATION
// =============================================================================

/** Required labels for all GCP resources */
const REQUIRED_LABELS = ['environment', 'project', 'managed-by'] as const;

/** Naming pattern: kebab-case */
const KEBAB_CASE_PATTERN = /^[a-z][a-z0-9-]*[a-z0-9]$/;

/** Resource types that should have labels */
const LABELED_RESOURCE_TYPES = [
  'gcp:organizations/project:Project',
  'gcp:cloudrunv2/service:Service',
  'gcp:sql/databaseInstance:DatabaseInstance',
  'gcp:pubsub/topic:Topic',
  'gcp:pubsub/subscription:Subscription',
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
// POLICIES
// =============================================================================

/**
 * Hexagonal Policy Pack - Enforce architecture conventions
 */
export const hexagonalPolicies = new PolicyPack('signet-hexagonal', {
  policies: [
    // =========================================================================
    // NAMING CONVENTIONS
    // =========================================================================
    {
      name: 'enforce-kebab-case-naming',
      description: 'Resource names must use kebab-case (lowercase with hyphens)',
      enforcementLevel: 'advisory',
      validateStack: (args, reportViolation) => {
        for (const resource of args.resources) {
          // Skip Pulumi internal resources
          if (resource.type.startsWith('pulumi:')) continue;

          // Check if name follows kebab-case
          const name = resource.name;
          if (name && name.length > 2 && !KEBAB_CASE_PATTERN.test(name)) {
            // Only warn if it looks like it should be kebab-case
            if (name.includes('_') || /[A-Z]/.test(name)) {
              reportViolation(
                `Resource "${name}" (${resource.type}) should use kebab-case naming. ` +
                  `Example: "my-service" instead of "my_service" or "myService"`
              );
            }
          }
        }
      },
    },

    {
      name: 'enforce-environment-suffix',
      description: 'Resource names should include environment suffix (dev, staging, prod)',
      enforcementLevel: 'advisory',
      validateStack: (args, reportViolation) => {
        const envSuffixes = ['-dev', '-staging', '-prod'];

        for (const resource of args.resources) {
          // Only check certain resource types
          const typePart = (t: string) => t.split('/')[1] ?? '';
          const isLabeledType = LABELED_RESOURCE_TYPES.some((t) =>
            resource.type.includes(typePart(t))
          );
          if (!isLabeledType) continue;

          const name = resource.name;
          const hasEnvSuffix = envSuffixes.some((suffix) =>
            name.endsWith(suffix)
          );

          if (!hasEnvSuffix) {
            reportViolation(
              `Resource "${name}" should include environment suffix ` +
                `(e.g., "${name}-dev", "${name}-prod") for clarity.`
            );
          }
        }
      },
    },

    // =========================================================================
    // LABELING REQUIREMENTS
    // =========================================================================
    {
      name: 'require-mandatory-labels',
      description: `GCP resources must have labels: ${REQUIRED_LABELS.join(', ')}`,
      enforcementLevel: 'mandatory',
      validateStack: (args, reportViolation) => {
        for (const resource of args.resources) {
          // Only check GCP resources
          if (!resource.type.startsWith('gcp:')) continue;

          // Get labels from resource props with type guards
          const props = resource.props;
          if (!isRecord(props)) continue;

          const labelsRaw = props['labels'] ?? props['userLabels'];
          const labels = isRecord(labelsRaw) ? labelsRaw : undefined;

          // Check for required labels
          for (const requiredLabel of REQUIRED_LABELS) {
            if (!labels || typeof labels[requiredLabel] !== 'string') {
              reportViolation(
                `GCP resource "${resource.name}" (${resource.type}) ` +
                  `missing required label: "${requiredLabel}". ` +
                  `Add labels.${requiredLabel} to the resource.`
              );
            }
          }
        }
      },
    },

    {
      name: 'validate-managed-by-label',
      description: 'managed-by label must be "signet" for Signet-managed resources',
      enforcementLevel: 'advisory',
      validateStack: (args, reportViolation) => {
        for (const resource of args.resources) {
          if (!resource.type.startsWith('gcp:')) continue;

          const props = resource.props;
          if (!isRecord(props)) continue;

          const labelsRaw = props['labels'] ?? props['userLabels'];
          const labels = isRecord(labelsRaw) ? labelsRaw : undefined;

          const managedBy = labels?.['managed-by'];
          if (typeof managedBy === 'string' && managedBy !== 'signet') {
            reportViolation(
              `Resource "${resource.name}" has managed-by="${managedBy}" ` +
                `but should be "signet" for consistency.`
            );
          }
        }
      },
    },

    // =========================================================================
    // ARCHITECTURE CONSTRAINTS
    // =========================================================================
    {
      name: 'limit-resources-per-stack',
      description: 'Stacks should not have too many resources (keep components focused)',
      enforcementLevel: 'advisory',
      validateStack: (args, reportViolation) => {
        const MAX_RESOURCES = 50;

        // Count non-Pulumi resources
        const resourceCount = args.resources.filter(
          (r) => !r.type.startsWith('pulumi:')
        ).length;

        if (resourceCount > MAX_RESOURCES) {
          reportViolation(
            `Stack has ${resourceCount} resources, which exceeds recommended max of ${MAX_RESOURCES}. ` +
              `Consider splitting into smaller, focused stacks (hexagonal components).`
          );
        }
      },
    },

    {
      name: 'require-project-resource',
      description: 'Stacks should have a GCP project resource for proper organization',
      enforcementLevel: 'advisory',
      validateStack: (args, reportViolation) => {
        const hasProject = args.resources.some(
          (r) => r.type === 'gcp:organizations/project:Project'
        );

        // Only report if there are GCP resources but no project
        const hasGcpResources = args.resources.some((r) =>
          r.type.startsWith('gcp:')
        );

        if (hasGcpResources && !hasProject) {
          reportViolation(
            'Stack contains GCP resources but no GCP Project resource. ' +
              'Consider using GcpProject component for proper project management.'
          );
        }
      },
    },

    // =========================================================================
    // DEPENDENCY HYGIENE
    // =========================================================================
    {
      name: 'check-resource-parents',
      description: 'Resources should have parent relationships for proper hierarchy',
      enforcementLevel: 'advisory',
      validateStack: (args, reportViolation) => {
        const orphanedResources: string[] = [];

        for (const resource of args.resources) {
          // Skip root-level resources and Pulumi internals
          if (resource.type.startsWith('pulumi:')) continue;
          if (resource.type === 'gcp:organizations/project:Project') continue;

          // Check if resource has a parent
          if (!resource.parent) {
            orphanedResources.push(`${resource.name} (${resource.type})`);
          }
        }

        if (orphanedResources.length > 5) {
          reportViolation(
            `${orphanedResources.length} resources lack parent relationships. ` +
              `Use ComponentResource pattern for better organization. ` +
              `Examples: ${orphanedResources.slice(0, 3).join(', ')}`
          );
        }
      },
    },
  ],
});

export default hexagonalPolicies;
