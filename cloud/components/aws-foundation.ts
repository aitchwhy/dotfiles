/**
 * AWS Foundation Component
 *
 * Generic infrastructure for ALL projects:
 * - VPC with public/private subnets
 * - Internet Gateway for public access
 * - NAT Gateway for private subnet egress
 *
 * NO project-specific resources (EC2, RDS, etc.) - those belong in project repos.
 */
import * as pulumi from "@pulumi/pulumi"
import * as awsx from "@pulumi/awsx"

export type AwsFoundationArgs = {
  readonly vpcCidr: string
  readonly azCount: number
  readonly tags?: Record<string, string>
}

export class AwsFoundation extends pulumi.ComponentResource {
  public readonly vpc: awsx.ec2.Vpc
  public readonly vpcId: pulumi.Output<string>
  public readonly publicSubnetIds: pulumi.Output<string[]>
  public readonly privateSubnetIds: pulumi.Output<string[]>
  public readonly defaultSecurityGroupId: pulumi.Output<string>

  constructor(
    name: string,
    args: AwsFoundationArgs,
    opts?: pulumi.ComponentResourceOptions
  ) {
    super("dotfiles:aws:Foundation", name, {}, opts)

    const defaultOpts = { parent: this }
    const baseTags = {
      "managed-by": "pulumi",
      environment: "shared",
      repository: "dotfiles",
      ...args.tags,
    }

    // VPC with public/private subnets using AWSX
    this.vpc = new awsx.ec2.Vpc(
      `${name}-vpc`,
      {
        cidrBlock: args.vpcCidr,
        numberOfAvailabilityZones: args.azCount,
        enableDnsHostnames: true,
        enableDnsSupport: true,
        natGateways: {
          strategy: awsx.ec2.NatGatewayStrategy.Single, // Cost-effective for personal use
        },
        subnetSpecs: [
          { type: awsx.ec2.SubnetType.Public, cidrMask: 24 },
          { type: awsx.ec2.SubnetType.Private, cidrMask: 24 },
        ],
        tags: { ...baseTags, Name: `${name}-vpc` },
      },
      defaultOpts
    )

    // Outputs
    this.vpcId = this.vpc.vpcId
    this.publicSubnetIds = this.vpc.publicSubnetIds
    this.privateSubnetIds = this.vpc.privateSubnetIds
    this.defaultSecurityGroupId = this.vpc.vpc.defaultSecurityGroupId

    this.registerOutputs({
      vpcId: this.vpcId,
      publicSubnetIds: this.publicSubnetIds,
      privateSubnetIds: this.privateSubnetIds,
      defaultSecurityGroupId: this.defaultSecurityGroupId,
    })
  }
}
