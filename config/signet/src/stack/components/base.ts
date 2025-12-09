/**
 * Base Component for Signet Infrastructure
 *
 * All Signet Pulumi components extend this base class.
 * Provides:
 *   - Stack definition access for version-aware provisioning
 *   - Standard environment/project/region configuration
 *   - Consistent resource naming
 *   - Default resource options (parent relationship)
 */
import * as pulumi from '@pulumi/pulumi';
import type {
  StackDefinition,
  Environment,
  GcpRegion,
} from '../schema';
import { STACK } from '../versions';

// =============================================================================
// COMPONENT ARGS
// =============================================================================

/**
 * Base arguments for all Signet components
 */
export type SignetComponentArgs = {
  /** Deployment environment */
  readonly environment: Environment;

  /** Project name (used in resource naming) */
  readonly project: string;

  /** GCP region (defaults to us-central1) */
  readonly region?: GcpRegion;

  /** Optional stack definition override (for testing) */
  readonly stack?: StackDefinition;

  /** Optional labels to apply to all resources */
  readonly labels?: Record<string, string>;
};

// =============================================================================
// BASE COMPONENT
// =============================================================================

/**
 * SignetComponent - Abstract base class for all infrastructure components
 *
 * Provides common functionality:
 * - Access to frozen stack versions
 * - Consistent naming conventions
 * - Default resource options with parent relationship
 * - Environment-specific configuration
 */
export abstract class SignetComponent extends pulumi.ComponentResource {
  /** Frozen stack definition (SSOT for versions) */
  protected readonly stack: StackDefinition;

  /** Deployment environment */
  protected readonly env: Environment;

  /** Project name */
  protected readonly project: string;

  /** GCP region */
  protected readonly region: GcpRegion;

  /** Base labels applied to all resources */
  protected readonly labels: Record<string, string>;

  constructor(
    type: string,
    name: string,
    args: SignetComponentArgs,
    opts?: pulumi.ComponentResourceOptions
  ) {
    super(type, name, {}, opts);

    this.stack = args.stack ?? STACK;
    this.env = args.environment;
    this.project = args.project;
    this.region = args.region ?? 'us-central1';

    // Merge provided labels with defaults
    this.labels = {
      environment: this.env,
      project: this.project,
      'managed-by': 'signet',
      'stack-version': this.stack.meta.ssotVersion,
      ...args.labels,
    };
  }

  /**
   * Get default resource options for child resources
   * Sets this component as the parent for proper hierarchy
   */
  protected defaultResourceOptions(): pulumi.ResourceOptions {
    return { parent: this };
  }

  /**
   * Generate a consistent resource name
   * Format: {project}-{name}-{environment}
   */
  protected resourceName(suffix: string): string {
    return `${this.project}-${suffix}-${this.env}`;
  }

  /**
   * Generate a short resource name (for resources with length limits)
   * Format: {project}-{name}
   */
  protected shortResourceName(suffix: string): string {
    return `${this.project}-${suffix}`;
  }

  /**
   * Check if this is a production environment
   * Useful for enabling deletion protection, backups, etc.
   */
  protected isProduction(): boolean {
    return this.env === 'prod';
  }

  /**
   * Get an npm package version from the stack
   */
  protected getNpmVersion(pkg: keyof StackDefinition['npm']): string {
    return this.stack.npm[pkg];
  }
}

// NOTE: Result types (Ok, Err, ComponentResult) were removed as unused.
// Components use Pulumi's native error handling. For application-level
// Result types, use src/lib/result.ts instead.
