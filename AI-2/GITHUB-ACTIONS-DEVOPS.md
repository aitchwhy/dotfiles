# GitHub Actions and DevOps Infrastructure Documentation

This document provides a detailed overview of the CI/CD pipeline and infrastructure management approach used in the Anterior platform.

## GitHub Actions Workflows

The platform uses GitHub Actions for continuous integration and deployment, with several specialized workflows handling different aspects of the process.

### CI Workflow (`ci.yaml`)

The primary CI workflow is triggered on pull requests and handles code quality validation:

- **Triggers**: Pull requests to any branch
- **Key Jobs**:
  - Code generation verification
  - Formatting and linting checks
  - Unit tests across services
  - Integration tests (non-draft PRs targeting master)
  - End-to-end tests (non-draft PRs targeting master)
  - Nix flake health checks (Linux and macOS)
  - CDKTF drift detection
  - Python lockfile validation

The CI workflow also triggers the ECR workflow to build and push Docker images for testing purposes.

### Deployment Workflows

#### Main Deployment (`cd.yaml`)

- **Triggers**:
  - Automatic: Pushes to the master branch
  - Manual: PRs with the "deploy" label
- **Purpose**: Coordinates the deployment of infrastructure and services
- **Process**:
  1. Determines environment name (production for master, PR-specific for PRs)
  2. Calls the reusable bake-and-deploy workflow

#### Bake and Deploy (`bake-and-deploy.yaml`)

A reusable workflow that handles the full deployment process:

- Builds and pushes Docker images to ECR
- Optionally deploys infrastructure stack
- Always deploys services stack
- Maintains proper dependency order

#### Stack Deployment (`deploy-stack.yaml`)

Low-level deployment workflow that:
- Takes a specific stack name (infra or services)
- Uses CDKTF to manage Terraform deployments
- Integrates with Terraform Cloud for state management
- Posts deployment URLs as PR comments

#### ECR Image Management (`ecr.yaml`)

- Handles building and pushing Docker images to Amazon ECR
- Uses Nix for reproducible builds
- Authenticates with AWS using OIDC
- Creates and updates repositories as needed

### Environment Management

- **Environment Cleanup**:
  - `destroy-env.yaml`: Manual workflow to remove an environment
  - `destroy-env-stack.yaml`: Removes a specific stack from an environment
  - `destroy-stale-envs.yaml`: Scheduled workflow that removes unused environments

### Additional Workflows

- **Security Scanning** (`semgrep.yaml`): Static code analysis for security issues
- **Task Evaluation** (`task-evals.yaml`): Workflow for validating specific tasks
- **PR Reminders** (`reminder.yaml`): Sends notifications for pending PRs

## Infrastructure as Code (DevOps Setup)

The platform uses a sophisticated infrastructure-as-code approach centered around CDKTF (Cloud Development Kit for Terraform).

### CDKTF Configuration

Located in `/platform/infra/cdktf`, the CDKTF setup:

- Uses TypeScript to define infrastructure components
- Organizes resources into logical stacks:
  - `stack-platform.ts`: Application services and ECS configuration
  - `stack-common.ts`: Shared infrastructure (VPC, networking, etc.)
  - `stack-dns-root.ts`: DNS zone management
  - `stack-secrets.ts`: Secrets management infrastructure

Key configuration files:
- `apps.ts`: Service definitions and container configuration
- `aws.ts`: AWS provider configuration
- `config.ts`: Environment-specific settings
- `cloudfront.ts`: CDN and static asset delivery
- `load-balancer.ts`: Application load balancer configuration

### AWS Integration

The platform runs primarily on AWS, with these key services:

- **Compute**: ECS Fargate for containerized services
- **Networking**: VPC, ALB, Route 53, CloudFront
- **Storage**: S3, RDS, ElastiCache
- **Security**: IAM, Secrets Manager, KMS

### Bastion & Emergency Access

The platform includes a secure bastion host for emergency access:

- Defined in `/platform/infra/bastion`
- SSH-based access with key authentication
- Tailscale integration for secure networking
- Limited privileges with audit logging

### Additional Infrastructure Components

- **Fake Service**: Test service for infrastructure validation
- **SQS Utilities**: Tools for managing message queues
- **Tailscale**: Secure network overlay configuration

## Deployment Workflow

### CI/CD Pipeline Flow

1. **Code Changes**:
   - Developer creates a branch and PR
   - PR triggers CI workflow for validation

2. **Continuous Integration**:
   - CI workflow validates code quality and tests
   - Docker images built and pushed to ECR
   - Integration and E2E tests validate functionality

3. **Continuous Deployment**:
   - For master branch: automatic deployment to production
   - For feature branches: optional deployment with "deploy" label
   - CDKTF synthesizes Terraform configuration
   - Terraform Cloud applies changes via stacks
   - Services deployed with latest image tags

4. **Environment Management**:
   - Production environment (master branch)
   - Per-PR ephemeral environments for testing
   - Automatic cleanup of unused environments

### Environment Creation Process

When a new environment is created:
1. Infrastructure stack creates core AWS resources
2. Services stack deploys containers to ECS
3. URLs and access details provided as PR comments
4. Environment persists until explicitly destroyed or PR is closed

## Security Considerations

### Secrets Management

- **GitHub Secrets**: Used for CI/CD credentials
- **AWS Secrets Manager**: Runtime secrets for services
- **Terraform Cloud Variables**: Protected infrastructure credentials

### Access Control

- **OIDC Integration**: Secure AWS authentication from GitHub Actions
- **Terraform Cloud Workspaces**: Permission boundaries for infrastructure
- **Branch Protection**: Production infrastructure changes require approval
- **Bastion Access**: Emergency SSH access with audit trail

### Deployment Safety

- **Terraform Drift Detection**: Alerts on manual infrastructure changes
- **Environment Isolation**: Testing environments separate from production
- **Comprehensive Testing**: Multiple validation layers before production changes
- **Rollback Capability**: Service versions can be reverted if needed

## Local Development Integration

The CI/CD and infrastructure setup integrates with local development through:

- **Nix Flakes**: Consistent environments between local and CI
- **Docker Compose**: Local service orchestration mirroring production
- **Shell Scripts**: Simplified commands for common operations

## Best Practices and Common Patterns

- **Infrastructure as Code**: All infrastructure defined through CDKTF
- **Immutable Infrastructure**: Resources recreated rather than modified
- **Environment Parity**: Identical configuration across environments
- **Separation of Concerns**: Infrastructure vs. service deployment
- **Automated Testing**: Comprehensive validation before deployment

---

This document provides an overview of the GitHub Actions workflows and infrastructure setup for the Anterior platform. For specific details on individual components, refer to the README files in the respective directories.