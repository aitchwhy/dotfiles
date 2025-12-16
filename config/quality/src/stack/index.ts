/**
 * Signet Stack - Version Registry
 *
 * Single source of truth for all version numbers.
 * Pulumi components are generated into projects, not bundled in CLI.
 *
 * @example
 * ```typescript
 * import { STACK, getNpmVersion } from '@signet/stack';
 *
 * // Access versions
 * console.log(STACK.npm.typescript); // "5.9.3"
 * console.log(getNpmVersion('effect')); // "3.19.9"
 * ```
 */

// Schema - Types and validation
export type {
  AppRunnerCpu,
  AppRunnerMemory,
  AwsRegion,
  BackendVersions,
  DatabaseVersions,
  Environment,
  FrontendVersions,
  InfraVersions,
  NpmVersions,
  ObservabilityVersions,
  PythonVersions,
  RdsInstanceClass,
  RuntimeVersions,
  ServiceVersions,
  StackDefinition,
  StackMeta,
  TestingVersions,
} from './schema';

export { stackDefinitionSchema } from './schema';

// Versions - SSOT
export {
  getDrift,
  getNpmVersion,
  getNpmVersions,
  isVersionMatch,
  STACK,
  validateStack,
  versionsJson,
} from './versions';
