/**
 * Secrets Component
 *
 * Manages GCP Secret Manager secrets:
 * - Single source of truth for all secrets
 * - Accessible by VM service account
 * - No .env files needed
 */
import * as pulumi from '@pulumi/pulumi'
import * as gcp from '@pulumi/gcp'

export type SecretsArgs = {
  readonly project: string
  readonly serviceAccountEmail: pulumi.Input<string>
}

type SecretDefinition = {
  readonly id: string
  readonly description: string
}

// Define secrets to manage (values set manually in GCP Console or via CLI)
const SECRET_DEFINITIONS: readonly SecretDefinition[] = [
  {
    id: 'tailscale-auth-key',
    description: 'Tailscale authentication key for VM registration',
  },
  {
    id: 'anthropic-api-key',
    description: 'Anthropic API key for Claude Code',
  },
  {
    id: 'github-token',
    description: 'GitHub personal access token',
  },
  {
    id: 'cachix-auth-token',
    description: 'Cachix authentication token for binary cache',
  },
] as const

export class SecretsResources extends pulumi.ComponentResource {
  public readonly secrets: Map<string, gcp.secretmanager.Secret>
  public readonly secretNames: pulumi.Output<string>[]

  constructor(
    name: string,
    args: SecretsArgs,
    opts?: pulumi.ComponentResourceOptions
  ) {
    super('cloud:gcp:Secrets', name, {}, opts)

    const defaultOpts = { parent: this }
    const protectedOpts = { ...defaultOpts, protect: true }

    this.secrets = new Map()
    this.secretNames = []

    // =========================================================================
    // Create Secret Manager Secrets
    // =========================================================================
    for (const def of SECRET_DEFINITIONS) {
      const secret = new gcp.secretmanager.Secret(
        `${name}-${def.id}`,
        {
          secretId: def.id,
          project: args.project,
          labels: {
            'managed-by': 'pulumi',
            purpose: 'cloud-vm',
          },
          replication: {
            auto: {},
          },
        },
        protectedOpts
      )

      this.secrets.set(def.id, secret)
      this.secretNames.push(secret.name)

      // Grant service account access to read this secret
      new gcp.secretmanager.SecretIamMember(
        `${name}-${def.id}-access`,
        {
          project: args.project,
          secretId: secret.secretId,
          role: 'roles/secretmanager.secretAccessor',
          member: pulumi.interpolate`serviceAccount:${args.serviceAccountEmail}`,
        },
        defaultOpts
      )
    }

    this.registerOutputs({
      secretCount: SECRET_DEFINITIONS.length,
      secretIds: SECRET_DEFINITIONS.map((d) => d.id),
    })
  }

  /**
   * Get a secret by its ID
   */
  getSecret(id: string): gcp.secretmanager.Secret | undefined {
    return this.secrets.get(id)
  }
}
