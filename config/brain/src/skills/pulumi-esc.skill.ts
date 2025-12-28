import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const pulumiEscSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('pulumi-esc'),
    description:
      'Pulumi ESC patterns for hybrid OIDC architecture. GitHub OIDC for AWS identity, ESC for config via pulumi-stacks and aws-secrets providers.',
    allowedTools: ['Read', 'Write', 'Edit', 'Bash', 'Grep'],
    tokenBudget: 800,
  },
  sections: [
    {
      heading: 'Overview',
      content: `# Pulumi ESC v2.0 - Hybrid OIDC Architecture`,
    },
    {
      heading: 'Core Principle: Separation of Concerns',
      content: `| Concern | Solution | Provider |
|---------|----------|----------|
| **Identity** (Who am I?) | GitHub OIDC | \`aws-actions/configure-aws-credentials\` |
| **Config** (What infra?) | Pulumi ESC | \`pulumi-stacks\` provider |
| **Secrets** (What secrets?) | Pulumi ESC | \`aws-secrets\` provider |

\`\`\`
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Actions Runner                        │
│                                                                  │
│  ┌──────────────────┐         ┌──────────────────┐              │
│  │  GitHub OIDC     │         │  Pulumi ESC      │              │
│  │  ──────────────  │         │  ──────────────  │              │
│  │  "Who am I?"     │         │  "What config?"  │              │
│  │                  │         │                  │              │
│  │  aws-actions/    │         │  pulumi-stacks   │              │
│  │  configure-creds │         │  aws-secrets     │              │
│  │        │         │         │        │         │              │
│  │        ▼         │         │        ▼         │              │
│  │   AWS IAM Role   │         │   Config Values  │              │
│  └──────────────────┘         └──────────────────┘              │
│           │                            │                         │
│           └────────────┬───────────────┘                         │
│                        ▼                                         │
│              Environment Variables                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ AWS_ACCESS_KEY_ID     ← GitHub OIDC                     │    │
│  │ ECS_CLUSTER, API_URL  ← ESC pulumi-stacks               │    │
│  │ DATABASE_URL          ← ESC aws-secrets                 │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
\`\`\``,
    },
    {
      heading: 'ESC Environment Structure',
      content: `\`\`\`
{org}/{project}/
├── base           # Constants: ports, regions, domains
├── dev            # imports: base + local dev overrides
├── staging        # imports: base + pulumi-stacks + aws-secrets
└── prod           # imports: base + pulumi-stacks + aws-secrets (prod)
\`\`\``,
    },
    {
      heading: 'Staging Environment (Full Pattern)',
      content: `\`\`\`yaml
# infra/pulumi/esc/staging.yaml
imports:
  - base

values:
  # 1. Pull infrastructure outputs from Pulumi stacks
  infra:
    fn::open::pulumi-stacks:
      stacks:
        infra:
          stack: myorg/infra/staging
        api:
          stack: myorg/api/staging

  # 2. Pull secrets from AWS Secrets Manager
  secrets:
    fn::open::aws-secrets:
      region: \${aws.region}
      login: \${aws.login}
      get:
        database:
          secretId: myapp/staging/database
        jwt:
          secretId: myapp/staging/jwt

  # 3. Compose URLs from infra outputs
  urls:
    api: https://api-staging.\${domain}
    ecr: \${infra.infra.ecr_repository_url}

environmentVariables:
  # From pulumi-stacks
  ECS_CLUSTER: \${infra.infra.ecs_cluster_name}
  ECS_SERVICE: \${infra.api.service_name}
  ECR_REPOSITORY_URL: \${infra.infra.ecr_repository_url}

  # From aws-secrets
  DATABASE_URL: \${secrets.database.url}
  JWT_SECRET: \${secrets.jwt.secret}

  # Composed
  API_URL: \${urls.api}
\`\`\``,
    },
    {
      heading: 'Why Hybrid OIDC?',
      content: `### Problem: Circular Dependency
\`\`\`
ESC needs AWS creds → to read AWS Secrets Manager
AWS creds come from → ??? (can't use ESC, not authenticated yet)
\`\`\`

### Solution: Orthogonal Auth
\`\`\`
GitHub OIDC → AWS IAM Role   (runner identity, no secrets)
ESC         → Config values  (uses GitHub's AWS session for aws-secrets)
\`\`\`

### Benefits
1. **No stored credentials** - GitHub OIDC is ephemeral
2. **Orthogonal failure modes** - AWS auth failure ≠ config failure
3. **Audit trail** - GitHub OIDC subject in CloudTrail
4. **Least privilege** - Separate roles for CI vs ESC`,
    },
    {
      heading: 'direnv Integration (Local Dev)',
      content: `\`\`\`bash
# .envrc - Fail-fast pattern
if [ -f flake.nix ]; then
  use flake
fi

# ESC for local dev (no pulumi-stacks needed)
ESC_ENV="\${ESC_ENV:-myorg/myproject/dev}"

if ! esc open "\${ESC_ENV}" --format shell > /tmp/esc-env 2>&1; then
  log_error "ESC failed: $(cat /tmp/esc-env)"
  return 1
fi

eval "$(cat /tmp/esc-env)"
log_status "Loaded ESC: \${ESC_ENV}"

# Fail-fast validation
: "\${DATABASE_URL:?DATABASE_URL required - check ESC}"
\`\`\``,
    },
    {
      heading: 'CLI Verification',
      content: `\`\`\`bash
# Test local dev
direnv reload
echo "API_URL=$API_URL"

# Test staging (requires OIDC trust policy)
esc open myorg/myproject/staging --format json | jq '.urls'

# Test pulumi-stacks integration
esc open myorg/myproject/staging --format json | jq '.stacks.infra'
\`\`\``,
    },
  ],
}
