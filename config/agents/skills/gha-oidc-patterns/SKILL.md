---
name: gha-oidc-patterns
description: GitHub Actions OIDC authentication patterns - AWS, Pulumi Cloud, Docker Hub. Official actions over curl|sh.
allowed-tools: Read, Write, Edit, Bash
token-budget: 600
version: 1.0.0
---

# GitHub Actions OIDC Patterns

## Core Principle: Official Actions Over Scripts

| Need | Official Action | Anti-Pattern |
|------|-----------------|--------------|
| AWS Auth | `aws-actions/configure-aws-credentials@v4` | Manual STS assume-role |
| Pulumi Auth | `pulumi/auth-actions@v1` | `curl \| sh` + PULUMI_ACCESS_TOKEN |
| ESC Config | `pulumi/esc-action@v1` | Manual `esc open` |
| ECR Login | `aws-actions/amazon-ecr-login@v2` | Manual `aws ecr get-login-password` |
| ECS Deploy | `aws-actions/amazon-ecs-deploy-task-definition@v2` | Manual `aws ecs update-service` |

## Hybrid OIDC Pattern

```yaml
permissions:
  contents: read
  id-token: write  # Required for OIDC

jobs:
  deploy:
    steps:
      # 1. AWS identity via GitHub OIDC
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/github-actions
          aws-region: us-east-1

      # 2. Pulumi Cloud auth (for ESC access)
      - uses: pulumi/auth-actions@v1
        with:
          organization: myorg
          requested-token-type: urn:pulumi:token-type:access_token:organization

      # 3. Load config from ESC
      - uses: pulumi/esc-action@v1
        with:
          environment: myorg/myproject/staging

      # 4. Use config (all values from ESC now)
      - run: echo "Cluster: $ECS_CLUSTER"
```

## AWS IAM Trust Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:ORG/REPO:*"
        }
      }
    }
  ]
}
```

## Anti-Patterns

| Don't | Do |
|-------|-----|
| `curl -fsSL https://get.pulumi.com \| sh` | `pulumi/actions@v6` |
| Store AWS keys in GitHub Secrets | GitHub OIDC with IAM role |
| Manual `esc open` in GHA | `pulumi/esc-action@v1` |
| Pass URLs between jobs via outputs | ESC `pulumi-stacks` provider |
| Multiple Pulumi CLI installs | Single `pulumi/auth-actions@v1` |
