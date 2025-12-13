/**
 * Pulumi Entry Point - Cloud Infrastructure
 *
 * Unified GCP infrastructure stack managing:
 * - Compute: NixOS VM with Tailscale access
 * - Storage: GCS buckets for DVC and snapshots
 * - Secrets: Secret Manager for all credentials
 *
 * 100% IaC - no manual resource creation.
 */
import * as pulumi from '@pulumi/pulumi'
import { CloudNixos } from './components/cloud-nixos'
import { SecretsResources } from './components/secrets'
import { StorageResources } from './components/storage'

// Get configuration
const config = new pulumi.Config()
const gcpConfig = new pulumi.Config('gcp')

const project = gcpConfig.require('project')
const region = gcpConfig.require('region')
const zone = gcpConfig.require('zone')

// Optional overrides
const machineType = config.get('machineType')
const diskSizeGb = config.getNumber('diskSizeGb')

// GCS location (multi-region for durability)
const storageLocation = config.get('storageLocation') ?? 'US'

// =============================================================================
// Compute Resources
// =============================================================================
const cloudNixos = new CloudNixos('cloud', {
  project,
  region,
  zone,
  machineType,
  diskSizeGb,
})

// =============================================================================
// Storage Resources
// =============================================================================
const storage = new StorageResources('cloud', {
  project,
  location: storageLocation,
  serviceAccountEmail: cloudNixos.serviceAccount.email,
})

// =============================================================================
// Secrets Resources
// =============================================================================
const secrets = new SecretsResources('cloud', {
  project,
  serviceAccountEmail: cloudNixos.serviceAccount.email,
})

// =============================================================================
// Exports
// =============================================================================

// Compute
export const publicIp = cloudNixos.publicIp
export const instanceId = cloudNixos.instanceId
export const instanceName = cloudNixos.instanceName
export const sshCommand = cloudNixos.sshCommand
export const serviceAccountEmail = cloudNixos.serviceAccount.email

// Storage
export const dataBucketUrl = storage.dataBucket.url
export const snapshotsBucketUrl = storage.snapshotsBucket.url

// Secrets (just the count, not the values)
export const secretCount = secrets.secretNames.length
