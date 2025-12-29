/**
 * Stack Configuration
 *
 * Version registry and forbidden package list.
 */

// Forbidden packages
export {
  FORBIDDEN_PACKAGES,
  type ForbiddenPackage,
  isForbidden,
} from './forbidden'
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
} from './schema'
export { StackDefinitionSchema } from './schema'
// Versions - SSOT
export {
  getDrift,
  getNpmVersion,
  getNpmVersions,
  isVersionMatch,
  STACK,
  validateStack,
  versionsJson,
} from './versions'
