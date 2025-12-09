/**
 * API Service Component
 *
 * Deploys a Hono API to Cloud Run with Signet best practices:
 * - Proper resource limits
 * - Health checks
 * - IAM configuration
 * - Environment variables from config/secrets
 */
import * as pulumi from '@pulumi/pulumi';
import * as gcp from '@pulumi/gcp';
import { SignetComponent, type SignetComponentArgs } from './base';
import type { CloudRunMemory, CloudRunCpu } from '../schema';

// =============================================================================
// COMPONENT ARGS
// =============================================================================

export type ApiServiceArgs = SignetComponentArgs & {
  /** GCP project ID */
  readonly projectId: pulumi.Input<string>;

  /** Container image URL (e.g., gcr.io/project/image:tag) */
  readonly image: pulumi.Input<string>;

  /** Port the container listens on (default: 3000) */
  readonly port?: number;

  /** Memory allocation (default: 512Mi) */
  readonly memory?: CloudRunMemory;

  /** CPU allocation (default: 1) */
  readonly cpu?: CloudRunCpu;

  /** Minimum instances (default: 0 for scale-to-zero) */
  readonly minInstances?: number;

  /** Maximum instances (default: 10) */
  readonly maxInstances?: number;

  /** Request timeout in seconds (default: 300) */
  readonly timeoutSeconds?: number;

  /** Concurrency per instance (default: 80) */
  readonly concurrency?: number;

  /** Environment variables */
  readonly envVars?: Record<string, pulumi.Input<string>>;

  /** Secret references (secret name -> env var name) */
  readonly secrets?: Record<string, { secretName: string; version?: string }>;

  /** Allow unauthenticated access (default: true for APIs) */
  readonly allowUnauthenticated?: boolean;

  /** Custom service account email */
  readonly serviceAccountEmail?: pulumi.Input<string>;

  /** VPC connector for private networking */
  readonly vpcConnector?: pulumi.Input<string>;

  /** Ingress setting (default: all for public APIs) */
  readonly ingress?: 'all' | 'internal' | 'internal-and-cloud-load-balancing';
};

// =============================================================================
// COMPONENT
// =============================================================================

/**
 * ApiService - Hono API on Cloud Run
 *
 * Features:
 * - Version-aware (pulls from stack definition)
 * - Configurable resources (memory, CPU, scaling)
 * - Secret Manager integration
 * - Health check configuration
 * - IAM for public/private access
 */
export class ApiService extends SignetComponent {
  /** The Cloud Run service */
  public readonly service: gcp.cloudrunv2.Service;

  /** Service URL */
  public readonly url: pulumi.Output<string>;

  /** Service name */
  public readonly serviceName: pulumi.Output<string>;

  constructor(
    name: string,
    args: ApiServiceArgs,
    opts?: pulumi.ComponentResourceOptions
  ) {
    super('signet:gcp:ApiService', name, args, opts);

    const defaultOpts = this.defaultResourceOptions();

    // Build environment variables array
    const envs: gcp.types.input.cloudrunv2.ServiceTemplateContainerEnv[] = [
      // Always include NODE_ENV
      { name: 'NODE_ENV', value: this.env === 'prod' ? 'production' : 'development' },
      // Include stack version for debugging
      { name: 'SIGNET_STACK_VERSION', value: this.stack.meta.ssotVersion },
      // Custom env vars
      ...Object.entries(args.envVars ?? {}).map(([envName, value]) => ({
        name: envName,
        value,
      })),
    ];

    // Add secret references
    for (const [envName, secretRef] of Object.entries(args.secrets ?? {})) {
      envs.push({
        name: envName,
        valueSource: {
          secretKeyRef: {
            secret: secretRef.secretName,
            version: secretRef.version ?? 'latest',
          },
        },
      });
    }

    // Build template object conditionally to satisfy exactOptionalPropertyTypes
    const template: gcp.types.input.cloudrunv2.ServiceTemplate = {
      labels: this.labels,
      scaling: {
        minInstanceCount: args.minInstances ?? 0,
        maxInstanceCount: args.maxInstances ?? 10,
      },
      timeout: `${args.timeoutSeconds ?? 300}s`,
      maxInstanceRequestConcurrency: args.concurrency ?? 80,
      containers: [
        {
          image: args.image,
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          ports: [{ containerPort: args.port ?? 3000, name: 'http1' }] as any,
          resources: {
            limits: {
              memory: args.memory ?? '512Mi',
              cpu: args.cpu ?? '1',
            },
            cpuIdle: true,
          },
          envs,
          startupProbe: {
            httpGet: {
              path: '/health',
              port: args.port ?? 3000,
            },
            initialDelaySeconds: 0,
            periodSeconds: 10,
            timeoutSeconds: 5,
            failureThreshold: 3,
          },
          livenessProbe: {
            httpGet: {
              path: '/health',
              port: args.port ?? 3000,
            },
            periodSeconds: 30,
            timeoutSeconds: 5,
            failureThreshold: 3,
          },
        },
      ],
    };

    // Add optional properties only if defined
    if (args.serviceAccountEmail !== undefined) {
      template.serviceAccount = args.serviceAccountEmail;
    }
    if (args.vpcConnector !== undefined) {
      template.vpcAccess = { connector: args.vpcConnector };
    }

    // Create Cloud Run service
    this.service = new gcp.cloudrunv2.Service(
      `${name}-service`,
      {
        name: this.shortResourceName(name),
        location: this.region,
        project: args.projectId,
        labels: this.labels,
        ingress: args.ingress ?? 'INGRESS_TRAFFIC_ALL',
        template,
        traffics: [
          {
            type: 'TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST',
            percent: 100,
          },
        ],
      },
      defaultOpts
    );

    this.serviceName = this.service.name;
    this.url = this.service.uri;

    // Configure IAM for access
    if (args.allowUnauthenticated !== false) {
      new gcp.cloudrunv2.ServiceIamMember(
        `${name}-invoker`,
        {
          name: this.service.name,
          location: this.service.location,
          project: args.projectId,
          role: 'roles/run.invoker',
          member: 'allUsers',
        },
        defaultOpts
      );
    }

    // Register outputs
    this.registerOutputs({
      url: this.url,
      serviceName: this.serviceName,
      region: this.region,
    });
  }
}
