/**
 * Pulumi Entry Point
 *
 * Migrated from infra/gcp.nix (Terranix configuration).
 * Manages cloud-nixos VM infrastructure on GCP.
 */
import * as pulumi from '@pulumi/pulumi'
import * as gcp from '@pulumi/gcp'
import { CloudNixos } from './components/cloud-nixos'

// Get configuration
const config = new pulumi.Config()
const gcpConfig = new pulumi.Config('gcp')

const project = gcpConfig.require('project')
const region = gcpConfig.require('region')
const zone = gcpConfig.require('zone')

// Optional overrides
const machineType = config.get('machineType')
const diskSizeGb = config.getNumber('diskSizeGb')

// Create the cloud-nixos infrastructure
const cloudNixos = new CloudNixos('cloud', {
  project,
  region,
  zone,
  machineType,
  diskSizeGb,
})

// Export outputs
export const publicIp = cloudNixos.publicIp
export const instanceId = cloudNixos.instanceId
export const instanceName = cloudNixos.instanceName
export const sshCommand = cloudNixos.sshCommand
export const serviceAccountEmail = cloudNixos.serviceAccount.email
