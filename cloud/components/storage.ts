/**
 * Storage Component
 *
 * Manages GCS buckets for data storage:
 * - Data bucket: DVC remote for health/finance data
 * - Snapshots bucket: Pipeline output storage
 */
import * as pulumi from '@pulumi/pulumi'
import * as gcp from '@pulumi/gcp'

export type StorageArgs = {
  readonly project: string
  readonly location: string
  readonly serviceAccountEmail: pulumi.Input<string>
}

export class StorageResources extends pulumi.ComponentResource {
  public readonly dataBucket: gcp.storage.Bucket
  public readonly snapshotsBucket: gcp.storage.Bucket

  constructor(
    name: string,
    args: StorageArgs,
    opts?: pulumi.ComponentResourceOptions
  ) {
    super('cloud:gcp:Storage', name, {}, opts)

    const defaultOpts = { parent: this }
    const protectedOpts = { ...defaultOpts, protect: true }

    // =========================================================================
    // Data Bucket (DVC Remote)
    // =========================================================================
    this.dataBucket = new gcp.storage.Bucket(
      `${name}-data`,
      {
        name: 'hank-systems-data',
        location: args.location,
        project: args.project,
        uniformBucketLevelAccess: true,
        versioning: {
          enabled: true,
        },
        lifecycleRules: [
          {
            action: {
              type: 'SetStorageClass',
              storageClass: 'NEARLINE',
            },
            condition: {
              age: 90,
            },
          },
          {
            action: {
              type: 'Delete',
            },
            condition: {
              age: 365,
              withState: 'ARCHIVED',
            },
          },
        ],
        labels: {
          purpose: 'dvc-remote',
          domain: 'personal-data',
          'managed-by': 'pulumi',
        },
      },
      protectedOpts
    )

    // =========================================================================
    // Snapshots Bucket (Pipeline Outputs)
    // =========================================================================
    this.snapshotsBucket = new gcp.storage.Bucket(
      `${name}-snapshots`,
      {
        name: 'hank-systems-snapshots',
        location: args.location,
        project: args.project,
        uniformBucketLevelAccess: true,
        versioning: {
          enabled: false,
        },
        lifecycleRules: [
          {
            action: {
              type: 'Delete',
            },
            condition: {
              age: 365,
            },
          },
        ],
        labels: {
          purpose: 'pipeline-snapshots',
          domain: 'personal-data',
          'managed-by': 'pulumi',
        },
      },
      defaultOpts
    )

    // =========================================================================
    // IAM Bindings
    // =========================================================================

    // Grant service account access to data bucket
    new gcp.storage.BucketIAMMember(
      `${name}-data-access`,
      {
        bucket: this.dataBucket.name,
        role: 'roles/storage.objectAdmin',
        member: pulumi.interpolate`serviceAccount:${args.serviceAccountEmail}`,
      },
      defaultOpts
    )

    // Grant service account access to snapshots bucket
    new gcp.storage.BucketIAMMember(
      `${name}-snapshots-access`,
      {
        bucket: this.snapshotsBucket.name,
        role: 'roles/storage.objectAdmin',
        member: pulumi.interpolate`serviceAccount:${args.serviceAccountEmail}`,
      },
      defaultOpts
    )

    this.registerOutputs({
      dataBucketName: this.dataBucket.name,
      dataBucketUrl: this.dataBucket.url,
      snapshotsBucketName: this.snapshotsBucket.name,
      snapshotsBucketUrl: this.snapshotsBucket.url,
    })
  }
}
