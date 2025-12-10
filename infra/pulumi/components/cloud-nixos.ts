/**
 * Cloud NixOS Component
 *
 * Replaces infra/gcp.nix Terranix configuration.
 * Manages the cloud-nixos VM with Tailscale access.
 *
 * Resources:
 * - google_service_account.cloud -> ServiceAccount
 * - google_compute_address.cloud -> StaticIP
 * - google_compute_firewall.allow-tailscale -> TailscaleFirewall
 * - google_compute_firewall.allow-icmp -> IcmpFirewall
 * - google_compute_instance.cloud -> Instance
 * - google_project_iam_member.monitoring-writer -> MonitoringIAM
 * - google_project_iam_member.logging-writer -> LoggingIAM
 */
import * as pulumi from '@pulumi/pulumi'
import * as gcp from '@pulumi/gcp'

export type CloudNixosArgs = {
  readonly project: string
  readonly region: string
  readonly zone: string
  readonly machineType?: string
  readonly diskSizeGb?: number
}

export class CloudNixos extends pulumi.ComponentResource {
  public readonly serviceAccount: gcp.serviceaccount.Account
  public readonly staticIp: gcp.compute.Address
  public readonly tailscaleFirewall: gcp.compute.Firewall
  public readonly icmpFirewall: gcp.compute.Firewall
  public readonly instance: gcp.compute.Instance

  // Outputs
  public readonly publicIp: pulumi.Output<string>
  public readonly instanceId: pulumi.Output<string>
  public readonly instanceName: pulumi.Output<string>
  public readonly sshCommand: pulumi.Output<string>

  constructor(
    name: string,
    args: CloudNixosArgs,
    opts?: pulumi.ComponentResourceOptions
  ) {
    super('dotfiles:gcp:CloudNixos', name, {}, opts)

    const defaultOpts = { parent: this }
    const protectedOpts = { ...defaultOpts, protect: true }

    // =========================================================================
    // Service Account
    // =========================================================================
    this.serviceAccount = new gcp.serviceaccount.Account(
      `${name}-sa`,
      {
        accountId: 'nixos-cloud-vm',
        displayName: 'NixOS Cloud VM Service Account',
        description: 'Service account for Cloud Monitoring and Logging',
        project: args.project,
      },
      protectedOpts
    )

    // IAM Bindings
    new gcp.projects.IAMMember(
      `${name}-monitoring`,
      {
        project: args.project,
        role: 'roles/monitoring.metricWriter',
        member: pulumi.interpolate`serviceAccount:${this.serviceAccount.email}`,
      },
      defaultOpts
    )

    new gcp.projects.IAMMember(
      `${name}-logging`,
      {
        project: args.project,
        role: 'roles/logging.logWriter',
        member: pulumi.interpolate`serviceAccount:${this.serviceAccount.email}`,
      },
      defaultOpts
    )

    // =========================================================================
    // Static IP
    // =========================================================================
    this.staticIp = new gcp.compute.Address(
      `${name}-ip`,
      {
        name: 'cloud-nixos-ip',
        region: args.region,
        description: 'Static IP for NixOS cloud instance',
        project: args.project,
      },
      protectedOpts
    )

    // =========================================================================
    // Firewall Rules
    // =========================================================================

    // Tailscale WireGuard
    this.tailscaleFirewall = new gcp.compute.Firewall(
      `${name}-tailscale`,
      {
        name: 'cloud-tailscale',
        network: 'default',
        description: 'Allow Tailscale direct connections (UDP 41641)',
        project: args.project,
        allows: [
          {
            protocol: 'udp',
            ports: ['41641'],
          },
        ],
        sourceRanges: ['0.0.0.0/0'],
        targetTags: ['tailscale'],
      },
      defaultOpts
    )

    // ICMP (ping)
    this.icmpFirewall = new gcp.compute.Firewall(
      `${name}-icmp`,
      {
        name: 'allow-icmp',
        network: 'default',
        description: 'Allow ICMP (ping)',
        project: args.project,
        allows: [
          {
            protocol: 'icmp',
          },
        ],
        sourceRanges: ['0.0.0.0/0'],
        targetTags: ['nixos'],
      },
      defaultOpts
    )

    // =========================================================================
    // Compute Instance
    // =========================================================================
    this.instance = new gcp.compute.Instance(
      `${name}-instance`,
      {
        name: 'cloud-nixos',
        machineType: args.machineType ?? 'e2-standard-4',
        zone: args.zone,
        project: args.project,

        // Boot Disk
        bootDisk: {
          initializeParams: {
            image: 'debian-cloud/debian-12',
            size: args.diskSizeGb ?? 100,
            type: 'pd-ssd',
            labels: {
              os: 'nixos',
              'managed-by': 'pulumi',
            },
          },
          autoDelete: true,
        },

        // Network
        networkInterfaces: [
          {
            network: 'default',
            accessConfigs: [
              {
                natIp: this.staticIp.address,
              },
            ],
          },
        ],

        // Metadata
        metadata: {
          'enable-oslogin': 'FALSE',
        },

        // Tags (for firewall rules)
        tags: ['nixos', 'tailscale'],

        // Labels
        labels: {
          environment: 'production',
          'managed-by': 'pulumi',
          os: 'nixos',
        },

        // Scheduling
        scheduling: {
          automaticRestart: true,
          onHostMaintenance: 'MIGRATE',
          preemptible: false,
        },

        // Service Account
        serviceAccount: {
          email: this.serviceAccount.email,
          scopes: [
            'https://www.googleapis.com/auth/cloud-platform',
            'https://www.googleapis.com/auth/logging.write',
            'https://www.googleapis.com/auth/monitoring.write',
          ],
        },

        // Shielded VM
        shieldedInstanceConfig: {
          enableSecureBoot: false, // NixOS needs custom boot
          enableVtpm: true,
          enableIntegrityMonitoring: true,
        },
      },
      protectedOpts // CRITICAL: prevent accidental destruction
    )

    // =========================================================================
    // Outputs
    // =========================================================================
    this.publicIp = this.staticIp.address
    this.instanceId = this.instance.instanceId
    this.instanceName = this.instance.name
    this.sshCommand = pulumi.interpolate`ssh hank@${this.staticIp.address}`

    this.registerOutputs({
      publicIp: this.publicIp,
      instanceId: this.instanceId,
      instanceName: this.instanceName,
      sshCommand: this.sshCommand,
    })
  }
}
