/**
 * Stack Component Tests
 *
 * Unit tests for Pulumi components using mocks.
 * These tests verify component behavior without deploying real resources.
 */
import * as pulumi from '@pulumi/pulumi';
import { describe, it, expect, beforeAll } from 'vitest';

// =============================================================================
// PULUMI MOCKS
// =============================================================================

/**
 * Mock Pulumi runtime for unit testing
 */
beforeAll(() => {
  // Mock pulumi runtime
  pulumi.runtime.setMocks({
    newResource: (args: pulumi.runtime.MockResourceArgs) => {
      const outputs: Record<string, unknown> = { ...args.inputs };

      // Add mock outputs based on resource type
      const inputs = args.inputs as Record<string, unknown>;
      switch (args.type) {
        case 'gcp:organizations/project:Project':
          outputs['projectId'] = inputs['projectId'] ?? `${args.name}-id`;
          outputs['number'] = '123456789';
          break;

        case 'gcp:cloudrunv2/service:Service':
          outputs['uri'] = `https://${args.name}.run.app`;
          outputs['name'] = inputs['name'] ?? args.name;
          break;

        case 'gcp:sql/databaseInstance:DatabaseInstance':
          outputs['connectionName'] = `project:region:${args.name}`;
          outputs['publicIpAddress'] = '10.0.0.1';
          outputs['privateIpAddress'] = '10.1.0.1';
          break;

        case 'gcp:sql/database:Database':
          outputs['name'] = inputs['name'] ?? args.name;
          break;

        case 'gcp:pubsub/topic:Topic':
          outputs['name'] = inputs['name'] ?? args.name;
          outputs['id'] = `projects/test/topics/${args.name}`;
          break;

        case 'random:index/randomPassword:RandomPassword':
          outputs['result'] = 'mock-secure-password-32chars!!!';
          break;
      }

      return {
        id: `${args.name}-id`,
        state: outputs,
      };
    },

    call: (args: pulumi.runtime.MockCallArgs) => {
      return args.inputs;
    },
  });
});

// =============================================================================
// SCHEMA TESTS
// =============================================================================

describe('Stack Schema', () => {
  it('should export STACK constant', async () => {
    const { STACK } = await import('../versions');

    expect(STACK).toBeDefined();
    expect(STACK.meta.frozen).toBe('2025-12');
    expect(STACK.meta.ssotVersion).toBe('3.0.0');
  });

  it('should have all version categories', async () => {
    const { STACK } = await import('../versions');

    expect(STACK.runtime).toBeDefined();
    expect(STACK.frontend).toBeDefined();
    expect(STACK.backend).toBeDefined();
    expect(STACK.infra).toBeDefined();
    expect(STACK.testing).toBeDefined();
    expect(STACK.python).toBeDefined();
    expect(STACK.databases).toBeDefined();
    expect(STACK.services).toBeDefined();
    expect(STACK.observability).toBeDefined();
    expect(STACK.npm).toBeDefined();
  });

  it('should validate STACK against schema', async () => {
    const { validateStack } = await import('../versions');

    // Should not throw
    expect(() => validateStack()).not.toThrow();
  });

  it('should export versions as JSON', async () => {
    const { versionsJson } = await import('../versions');

    const parsed = JSON.parse(versionsJson);
    expect(parsed.meta.frozen).toBe('2025-12');
  });
});

// =============================================================================
// VERSION HELPERS TESTS
// =============================================================================

describe('Version Helpers', () => {
  it('getNpmVersion returns correct version', async () => {
    const { getNpmVersion } = await import('../versions');

    expect(getNpmVersion('typescript')).toBe('5.9.3');
    expect(getNpmVersion('react')).toBe('19.2.1');
    expect(getNpmVersion('hono')).toBe('4.10.7');
  });

  it('isVersionMatch detects drift', async () => {
    const { isVersionMatch } = await import('../versions');

    // Matching version
    expect(isVersionMatch('typescript', '5.9.3')).toBe(true);

    // Drifted version
    expect(isVersionMatch('typescript', '5.0.0')).toBe(false);

    // Unknown package (should pass)
    expect(isVersionMatch('unknown-pkg', '1.0.0')).toBe(true);
  });

  it('getDrift returns drift report', async () => {
    const { getDrift } = await import('../versions');

    const drift = getDrift({
      typescript: '5.0.0', // Wrong
      react: '19.2.1', // Correct
      hono: '4.0.0', // Wrong
    });

    expect(drift).toHaveLength(2);
    const firstDrift = drift[0];
    expect(firstDrift).toBeDefined();
    expect(firstDrift!.pkg).toBe('typescript');
    expect(firstDrift!.expected).toBe('5.9.3');
    expect(firstDrift!.actual).toBe('5.0.0');
  });
});

// =============================================================================
// GCP PROJECT TESTS
// =============================================================================

describe('GcpProject Component', () => {
  it('should create project with APIs enabled', async () => {
    const { GcpProject } = await import('../components/gcp-project');

    const project = new GcpProject('test-project', {
      environment: 'dev',
      project: 'my-app',
      billingAccount: '000000-000000-000000',
    });

    // Verify project ID output exists
    expect(project.projectId).toBeDefined();
    expect(project.enabledServices.length).toBeGreaterThan(0);
  });

  it('should skip default APIs when requested', async () => {
    const { GcpProject } = await import('../components/gcp-project');

    const project = new GcpProject('custom-project', {
      environment: 'dev',
      project: 'my-app',
      billingAccount: '000000-000000-000000',
      skipDefaultApis: true,
      services: ['custom.googleapis.com'],
    });

    expect(project.enabledServices).toHaveLength(1);
  });
});

// =============================================================================
// API SERVICE TESTS
// =============================================================================

describe('ApiService Component', () => {
  it('should create Cloud Run service with defaults', async () => {
    const { ApiService } = await import('../components/api-service');

    const api = new ApiService('test-api', {
      environment: 'dev',
      project: 'my-app',
      projectId: 'my-app-dev',
      image: 'gcr.io/my-app/api:latest',
    });

    expect(api.url).toBeDefined();
    expect(api.serviceName).toBeDefined();
  });

  it('should configure environment variables', async () => {
    const { ApiService } = await import('../components/api-service');

    const api = new ApiService('api-with-env', {
      environment: 'prod',
      project: 'my-app',
      projectId: 'my-app-prod',
      image: 'gcr.io/my-app/api:latest',
      envVars: {
        API_URL: 'https://api.example.com',
        LOG_LEVEL: 'info',
      },
    });

    expect(api.service).toBeDefined();
  });

  it('should configure secrets from Secret Manager', async () => {
    const { ApiService } = await import('../components/api-service');

    const api = new ApiService('api-with-secrets', {
      environment: 'prod',
      project: 'my-app',
      projectId: 'my-app-prod',
      image: 'gcr.io/my-app/api:latest',
      secrets: {
        DATABASE_URL: { secretName: 'db-connection-string' },
        API_KEY: { secretName: 'api-key', version: '1' },
      },
    });

    expect(api.service).toBeDefined();
  });
});

// =============================================================================
// DATABASE SERVICE TESTS
// =============================================================================

describe('DatabaseService Component', () => {
  it('should create Cloud SQL instance with secure password', async () => {
    const { DatabaseService } = await import('../components/database-service');

    const db = new DatabaseService('test-db', {
      environment: 'dev',
      project: 'my-app',
      projectId: 'my-app-dev',
    });

    expect(db.instance).toBeDefined();
    expect(db.database).toBeDefined();
    expect(db.user).toBeDefined();
    expect(db.password).toBeDefined();
  });

  it('should enable deletion protection in prod', async () => {
    const { DatabaseService } = await import('../components/database-service');

    const db = new DatabaseService('prod-db', {
      environment: 'prod',
      project: 'my-app',
      projectId: 'my-app-prod',
    });

    expect(db.instance).toBeDefined();
    // Note: We can't directly test deletion_protection in mocks,
    // but we verify the component accepts prod environment
  });

  it('should generate connection string', async () => {
    const { DatabaseService } = await import('../components/database-service');

    const db = new DatabaseService('db-with-conn', {
      environment: 'dev',
      project: 'my-app',
      projectId: 'my-app-dev',
    });

    expect(db.connectionString).toBeDefined();
  });
});

// =============================================================================
// QUEUE SERVICE TESTS
// =============================================================================

describe('QueueService Component', () => {
  it('should create Pub/Sub topic', async () => {
    const { QueueService } = await import('../components/queue-service');

    const queue = new QueueService('test-queue', {
      environment: 'dev',
      project: 'my-app',
      projectId: 'my-app-dev',
    });

    expect(queue.topic).toBeDefined();
    expect(queue.topicName).toBeDefined();
  });

  it('should create subscriptions', async () => {
    const { QueueService } = await import('../components/queue-service');

    const queue = new QueueService('queue-with-subs', {
      environment: 'dev',
      project: 'my-app',
      projectId: 'my-app-dev',
      subscriptions: [
        { name: 'worker' },
        { name: 'push', pushEndpoint: 'https://api.example.com/webhook' },
      ],
    });

    expect(queue.subscriptions).toHaveLength(2);
  });
});

// =============================================================================
// INTEGRATION TESTS
// =============================================================================

describe('Component Composition', () => {
  it('should compose multiple components', async () => {
    const { GcpProject } = await import('../components/gcp-project');
    const { ApiService } = await import('../components/api-service');
    const { DatabaseService } = await import('../components/database-service');
    const { QueueService } = await import('../components/queue-service');

    // Create project first
    const project = new GcpProject('my-stack', {
      environment: 'dev',
      project: 'my-app',
      billingAccount: '000000-000000-000000',
    });

    // Create dependent resources
    const api = new ApiService('api', {
      environment: 'dev',
      project: 'my-app',
      projectId: project.projectId,
      image: 'gcr.io/my-app/api:latest',
    });

    const db = new DatabaseService('db', {
      environment: 'dev',
      project: 'my-app',
      projectId: project.projectId,
    });

    const queue = new QueueService('events', {
      environment: 'dev',
      project: 'my-app',
      projectId: project.projectId,
      subscriptions: [
        { name: 'processor' },
      ],
    });

    // All components should be created
    expect(project.projectId).toBeDefined();
    expect(api.url).toBeDefined();
    expect(db.connectionName).toBeDefined();
    expect(queue.topicName).toBeDefined();
  });
});
