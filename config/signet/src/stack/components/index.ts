/**
 * Signet GCP Components
 *
 * Composable, reusable infrastructure components for GCP.
 * All components are version-aware via the STACK definition.
 */

// Base component
export { SignetComponent, type SignetComponentArgs, Ok, Err, type ComponentResult } from './base';

// GCP Components
export { GcpProject, type GcpProjectArgs } from './gcp-project';
export { ApiService, type ApiServiceArgs } from './api-service';
export { DatabaseService, type DatabaseServiceArgs } from './database-service';
export { QueueService, type QueueServiceArgs, type SubscriptionConfig } from './queue-service';
