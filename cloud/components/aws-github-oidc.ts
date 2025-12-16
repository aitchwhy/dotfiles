/**
 * AWS GitHub OIDC Component
 *
 * Enables GitHub Actions to authenticate to AWS without static credentials.
 * Creates:
 * - OIDC Provider for GitHub
 * - IAM Role with trust policy for GitHub repos
 * - Policy attachments for common operations
 *
 * Usage in GitHub Actions:
 *   - uses: aws-actions/configure-aws-credentials@v4
 *     with:
 *       role-to-assume: arn:aws:iam::952084167040:role/github-actions
 *       aws-region: us-east-1
 */
import * as pulumi from "@pulumi/pulumi"
import * as aws from "@pulumi/aws"

export type GitHubOidcArgs = {
  readonly githubOrg: string
  readonly allowedRepos?: readonly string[] // Empty = all repos in org
  readonly tags?: Record<string, string>
}

export class GitHubOidc extends pulumi.ComponentResource {
  public readonly provider: aws.iam.OpenIdConnectProvider
  public readonly role: aws.iam.Role
  public readonly roleArn: pulumi.Output<string>

  constructor(
    name: string,
    args: GitHubOidcArgs,
    opts?: pulumi.ComponentResourceOptions
  ) {
    super("dotfiles:aws:GitHubOidc", name, {}, opts)

    const defaultOpts = { parent: this }
    const baseTags = {
      "managed-by": "pulumi",
      purpose: "github-oidc",
      repository: "dotfiles",
      ...args.tags,
    }

    // GitHub OIDC Provider (one per AWS account)
    this.provider = new aws.iam.OpenIdConnectProvider(
      `${name}-provider`,
      {
        url: "https://token.actions.githubusercontent.com",
        clientIdLists: ["sts.amazonaws.com"],
        // GitHub's OIDC thumbprint (stable)
        thumbprintLists: ["6938fd4d98bab03faadb97b34396831e3780aea1"],
        tags: baseTags,
      },
      defaultOpts
    )

    // Build subject filter for allowed repos
    const subjectFilter =
      args.allowedRepos && args.allowedRepos.length > 0
        ? args.allowedRepos.map((repo) => `repo:${args.githubOrg}/${repo}:*`)
        : [`repo:${args.githubOrg}/*:*`]

    // IAM Role for GitHub Actions
    this.role = new aws.iam.Role(
      `${name}-role`,
      {
        name: "github-actions",
        assumeRolePolicy: pulumi
          .all([this.provider.arn])
          .apply(([providerArn]) =>
            JSON.stringify({
              Version: "2012-10-17",
              Statement: [
                {
                  Effect: "Allow",
                  Principal: { Federated: providerArn },
                  Action: "sts:AssumeRoleWithWebIdentity",
                  Condition: {
                    StringEquals: {
                      "token.actions.githubusercontent.com:aud":
                        "sts.amazonaws.com",
                    },
                    StringLike: {
                      "token.actions.githubusercontent.com:sub": subjectFilter,
                    },
                  },
                },
              ],
            })
          ),
        tags: baseTags,
      },
      defaultOpts
    )

    // Attach PowerUserAccess policy (broad permissions for CI/CD)
    // Note: Can be scoped down later based on actual needs
    new aws.iam.RolePolicyAttachment(
      `${name}-poweruser`,
      {
        role: this.role.name,
        policyArn: "arn:aws:iam::aws:policy/PowerUserAccess",
      },
      defaultOpts
    )

    this.roleArn = this.role.arn

    this.registerOutputs({
      providerArn: this.provider.arn,
      roleArn: this.roleArn,
    })
  }
}
