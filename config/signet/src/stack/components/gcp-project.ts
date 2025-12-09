/**
 * GCP Project Component
 *
 * Creates a GCP project with required APIs enabled for Signet applications.
 * This is the foundation component that other GCP resources depend on.
 */
import * as pulumi from '@pulumi/pulumi';
import * as gcp from '@pulumi/gcp';
import { SignetComponent, type SignetComponentArgs } from './base';

// =============================================================================
// COMPONENT ARGS
// =============================================================================

export type GcpProjectArgs = SignetComponentArgs & {
  /** GCP billing account ID */
  readonly billingAccount: string;

  /** GCP organization ID (optional) */
  readonly orgId?: string;

  /** GCP folder ID (optional, for organizing projects) */
  readonly folderId?: string;

  /** APIs to enable (defaults to Signet standard set) */
  readonly services?: readonly string[];

  /** Skip default APIs (only enable explicitly listed services) */
  readonly skipDefaultApis?: boolean;
};

// =============================================================================
// DEFAULT APIS
// =============================================================================

/** Standard APIs enabled for all Signet projects */
const DEFAULT_APIS = [
  'run.googleapis.com', // Cloud Run
  'sqladmin.googleapis.com', // Cloud SQL
  'pubsub.googleapis.com', // Pub/Sub
  'secretmanager.googleapis.com', // Secret Manager
  'cloudresourcemanager.googleapis.com', // Resource Manager
  'iam.googleapis.com', // IAM
  'cloudbuild.googleapis.com', // Cloud Build
  'artifactregistry.googleapis.com', // Artifact Registry
  'logging.googleapis.com', // Cloud Logging
  'monitoring.googleapis.com', // Cloud Monitoring
] as const;

// =============================================================================
// COMPONENT
// =============================================================================

/**
 * GcpProject - Base GCP project with required APIs enabled
 *
 * Features:
 * - Creates GCP project with billing account
 * - Enables standard Signet APIs by default
 * - Supports custom API list
 * - Proper labeling for cost allocation
 */
export class GcpProject extends SignetComponent {
  /** The created GCP project */
  public readonly gcpProject: gcp.organizations.Project;

  /** Project ID output */
  public readonly projectId: pulumi.Output<string>;

  /** Project number output */
  public readonly projectNumber: pulumi.Output<string>;

  /** Enabled service resources */
  public readonly enabledServices: gcp.projects.Service[];

  constructor(
    name: string,
    args: GcpProjectArgs,
    opts?: pulumi.ComponentResourceOptions
  ) {
    super('signet:gcp:Project', name, args, opts);

    const defaultOpts = this.defaultResourceOptions();

    // Generate project ID (must be globally unique, 6-30 chars)
    const projectId = this.resourceName(name).substring(0, 30).toLowerCase();

    // Create GCP project - conditionally include optional properties
    const projectArgs: gcp.organizations.ProjectArgs = {
      name: this.resourceName(name),
      projectId,
      billingAccount: args.billingAccount,
      labels: this.labels,
      autoCreateNetwork: false, // We'll create our own VPC if needed
    };
    if (args.orgId !== undefined) {
      projectArgs.orgId = args.orgId;
    }
    if (args.folderId !== undefined) {
      projectArgs.folderId = args.folderId;
    }

    this.gcpProject = new gcp.organizations.Project(
      `${name}-project`,
      projectArgs,
      defaultOpts
    );

    this.projectId = this.gcpProject.projectId;
    this.projectNumber = this.gcpProject.number;

    // Determine which APIs to enable
    const servicesToEnable = args.skipDefaultApis
      ? (args.services ?? [])
      : [...DEFAULT_APIS, ...(args.services ?? [])];

    // Enable APIs (with dependencies to ensure project exists first)
    this.enabledServices = servicesToEnable.map(
      (service) =>
        new gcp.projects.Service(
          `${name}-${service.split('.')[0]}`,
          {
            project: this.projectId,
            service,
            disableOnDestroy: false, // Keep APIs enabled if stack is destroyed
            disableDependentServices: false,
          },
          {
            ...defaultOpts,
            dependsOn: [this.gcpProject],
          }
        )
    );

    // Register outputs
    this.registerOutputs({
      projectId: this.projectId,
      projectNumber: this.projectNumber,
      enabledApiCount: this.enabledServices.length,
    });
  }

  /**
   * Wait for all APIs to be enabled before creating dependent resources
   */
  public waitForApis(): pulumi.Resource[] {
    return this.enabledServices;
  }
}
