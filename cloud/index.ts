/**
 * Pulumi Entry Point - AWS Foundation Infrastructure
 *
 * Generic infrastructure shared by ALL projects:
 * - VPC with public/private subnets
 * - GitHub OIDC for CI/CD authentication
 *
 * NO project-specific resources here.
 * Projects create their own resources using these foundations.
 *
 * AWS Account: 952084167040
 * Region: us-east-1
 */
import * as pulumi from "@pulumi/pulumi"
import { AwsFoundation } from "./components/aws-foundation.ts"
import { GitHubOidc } from "./components/aws-github-oidc.ts"

// Configuration
const config = new pulumi.Config("cloud")
const vpcCidr = config.get("vpcCidr") ?? "10.0.0.0/16"
const azCount = config.getNumber("azCount") ?? 2
const githubOrg = config.require("githubOrg")

// =============================================================================
// Foundation Infrastructure
// =============================================================================
const foundation = new AwsFoundation("foundation", {
  vpcCidr,
  azCount,
})

// =============================================================================
// GitHub OIDC
// =============================================================================
const githubOidc = new GitHubOidc("github", {
  githubOrg,
  // Allow all repos from the org by default
})

// =============================================================================
// Exports
// =============================================================================

// VPC
export const vpcId = foundation.vpcId
export const publicSubnetIds = foundation.publicSubnetIds
export const privateSubnetIds = foundation.privateSubnetIds
export const defaultSecurityGroupId = foundation.defaultSecurityGroupId

// GitHub OIDC
export const githubActionsRoleArn = githubOidc.roleArn

// Metadata
export const awsAccountId = "952084167040"
export const awsRegion = "us-east-1"
