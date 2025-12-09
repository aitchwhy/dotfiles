/**
 * Signet Stack - Infrastructure as Code
 *
 * Pulumi TypeScript components for GCP infrastructure.
 * This is the single source of truth for stack versions and
 * composable infrastructure components.
 *
 * @example
 * ```typescript
 * import { STACK, GcpProject, ApiService } from '@signet/stack';
 *
 * // Access versions
 * console.log(STACK.npm.typescript); // "5.9.3"
 *
 * // Create infrastructure
 * const project = new GcpProject('my-project', {
 *   environment: 'dev',
 *   project: 'my-app',
 *   billingAccount: 'XXXXX-XXXXX-XXXXX',
 * });
 *
 * const api = new ApiService('api', {
 *   environment: 'dev',
 *   project: 'my-app',
 *   projectId: project.projectId,
 *   image: 'gcr.io/my-app/api:latest',
 * });
 * ```
 */

// Schema - Types and validation
export type {
  StackDefinition,
  StackMeta,
  RuntimeVersions,
  FrontendVersions,
  BackendVersions,
  InfraVersions,
  TestingVersions,
  PythonVersions,
  DatabaseVersions,
  ServiceVersions,
  ObservabilityVersions,
  NpmVersions,
  Environment,
  GcpRegion,
  DatabaseTier,
  CloudRunMemory,
  CloudRunCpu,
} from './schema';

export { stackDefinitionSchema } from './schema';

// Versions - SSOT
export {
  STACK,
  validateStack,
  versionsJson,
  getNpmVersion,
  getNpmVersions,
  isVersionMatch,
  getDrift,
} from './versions';

// Components - GCP Infrastructure
export {
  SignetComponent,
  type SignetComponentArgs,
  Ok,
  Err,
  type ComponentResult,
  GcpProject,
  type GcpProjectArgs,
  ApiService,
  type ApiServiceArgs,
  DatabaseService,
  type DatabaseServiceArgs,
  QueueService,
  type QueueServiceArgs,
  type SubscriptionConfig,
} from './components';

// Policies - Policy as Code (lazy-loaded to avoid process.exit in tests)
// Use getPolicyPacks() when you need actual PolicyPack instances
export { getPolicyPacks, type PolicyPack } from './policies';
