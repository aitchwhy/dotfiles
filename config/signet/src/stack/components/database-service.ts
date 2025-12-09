/**
 * Database Service Component
 *
 * Creates a Cloud SQL PostgreSQL instance with Signet best practices:
 * - Secure password generation
 * - Automatic backups
 * - Deletion protection in production
 * - Drizzle-ready configuration
 */
import * as pulumi from '@pulumi/pulumi';
import * as gcp from '@pulumi/gcp';
import * as random from '@pulumi/random';
import { SignetComponent, type SignetComponentArgs } from './base';
import type { DatabaseTier } from '../schema';

// =============================================================================
// COMPONENT ARGS
// =============================================================================

export type DatabaseServiceArgs = SignetComponentArgs & {
  /** GCP project ID */
  readonly projectId: pulumi.Input<string>;

  /** Database tier (default: db-f1-micro for dev, db-custom-1-3840 for prod) */
  readonly tier?: DatabaseTier;

  /** Disk size in GB (default: 10) */
  readonly diskSizeGb?: number;

  /** Enable high availability (default: true for prod) */
  readonly highAvailability?: boolean;

  /** PostgreSQL version (default: POSTGRES_15) */
  readonly postgresVersion?: 'POSTGRES_14' | 'POSTGRES_15' | 'POSTGRES_16';

  /** Authorized networks for external access */
  readonly authorizedNetworks?: readonly {
    name: string;
    cidr: string;
  }[];

  /** Enable point-in-time recovery (default: true for prod) */
  readonly pointInTimeRecovery?: boolean;

  /** Backup start time in UTC (default: 03:00) */
  readonly backupStartTime?: string;

  /** Database name (default: project name with underscores) */
  readonly databaseName?: string;

  /** Database user name (default: app) */
  readonly userName?: string;

  /** Enable deletion protection (default: true for prod) */
  readonly deletionProtection?: boolean;

  /** Enable private IP only (no public IP) */
  readonly privateIpOnly?: boolean;

  /** VPC network for private IP */
  readonly vpcNetwork?: pulumi.Input<string>;
};

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/**
 * Build IP configuration object, avoiding undefined properties for exactOptionalPropertyTypes
 */
function buildIpConfiguration(
  args: DatabaseServiceArgs
): gcp.types.input.sql.DatabaseInstanceSettingsIpConfiguration {
  const config: gcp.types.input.sql.DatabaseInstanceSettingsIpConfiguration = {
    ipv4Enabled: !args.privateIpOnly,
    sslMode: 'ENCRYPTED_ONLY',
  };

  if (args.vpcNetwork !== undefined) {
    config.privateNetwork = args.vpcNetwork;
  }

  if (args.authorizedNetworks && args.authorizedNetworks.length > 0) {
    config.authorizedNetworks = args.authorizedNetworks.map((n) => ({
      name: n.name,
      value: n.cidr,
    }));
  }

  return config;
}

// =============================================================================
// COMPONENT
// =============================================================================

/**
 * DatabaseService - Cloud SQL PostgreSQL with Drizzle-ready configuration
 *
 * Features:
 * - Auto-generated secure password (stored in output)
 * - Automatic daily backups
 * - Point-in-time recovery for production
 * - Deletion protection for production
 * - Ready for Drizzle ORM connections
 */
export class DatabaseService extends SignetComponent {
  /** The Cloud SQL instance */
  public readonly instance: gcp.sql.DatabaseInstance;

  /** The database */
  public readonly database: gcp.sql.Database;

  /** The database user */
  public readonly user: gcp.sql.User;

  /** Connection name for Cloud SQL proxy */
  public readonly connectionName: pulumi.Output<string>;

  /** Database name */
  public readonly databaseName: pulumi.Output<string>;

  /** Database user name */
  public readonly userName: pulumi.Output<string>;

  /** Database password (secret) */
  public readonly password: pulumi.Output<string>;

  /** Public IP address (if enabled) */
  public readonly publicIp: pulumi.Output<string>;

  /** Private IP address (if enabled) */
  public readonly privateIp: pulumi.Output<string>;

  /** Connection string for Drizzle */
  public readonly connectionString: pulumi.Output<string>;

  constructor(
    name: string,
    args: DatabaseServiceArgs,
    opts?: pulumi.ComponentResourceOptions
  ) {
    super('signet:gcp:DatabaseService', name, args, opts);

    const defaultOpts = this.defaultResourceOptions();
    const isProd = this.isProduction();

    // Generate secure password
    const dbPassword = new random.RandomPassword(
      `${name}-password`,
      {
        length: 32,
        special: true,
        overrideSpecial: '!#$%&*()-_=+[]{}<>:?', // Safe for connection strings
      },
      defaultOpts
    );

    // Determine tier based on environment
    const tier = args.tier ?? (isProd ? 'db-custom-1-3840' : 'db-f1-micro');

    // Create Cloud SQL instance
    this.instance = new gcp.sql.DatabaseInstance(
      `${name}-instance`,
      {
        name: this.resourceName(name),
        databaseVersion: args.postgresVersion ?? 'POSTGRES_15',
        region: this.region,
        project: args.projectId,
        settings: {
          tier,
          diskSize: args.diskSizeGb ?? 10,
          diskType: 'PD_SSD',
          diskAutoresize: true,
          diskAutoresizeLimit: isProd ? 100 : 20,
          availabilityType:
            args.highAvailability ?? isProd ? 'REGIONAL' : 'ZONAL',
          backupConfiguration: {
            enabled: true,
            startTime: args.backupStartTime ?? '03:00',
            pointInTimeRecoveryEnabled: args.pointInTimeRecovery ?? isProd,
            backupRetentionSettings: {
              retainedBackups: isProd ? 30 : 7,
              retentionUnit: 'COUNT',
            },
            transactionLogRetentionDays: isProd ? 7 : 1,
          },
          ipConfiguration: buildIpConfiguration(args),
          maintenanceWindow: {
            day: 7, // Sunday
            hour: 4, // 4 AM
            updateTrack: 'stable',
          },
          databaseFlags: [
            // Performance optimizations
            { name: 'max_connections', value: '100' },
            { name: 'log_checkpoints', value: 'on' },
            { name: 'log_connections', value: 'on' },
            { name: 'log_disconnections', value: 'on' },
            { name: 'log_lock_waits', value: 'on' },
          ],
          userLabels: this.labels,
        },
        deletionProtection: args.deletionProtection ?? isProd,
      },
      defaultOpts
    );

    // Database name: project with underscores (PostgreSQL convention)
    const dbName =
      args.databaseName ?? this.project.replace(/-/g, '_');
    const dbUserName = args.userName ?? 'app';

    // Create database
    this.database = new gcp.sql.Database(
      `${name}-database`,
      {
        name: dbName,
        instance: this.instance.name,
        project: args.projectId,
        charset: 'UTF8',
        collation: 'en_US.UTF8',
      },
      {
        ...defaultOpts,
        dependsOn: [this.instance],
      }
    );

    // Create user
    this.user = new gcp.sql.User(
      `${name}-user`,
      {
        name: dbUserName,
        instance: this.instance.name,
        password: dbPassword.result,
        project: args.projectId,
      },
      {
        ...defaultOpts,
        dependsOn: [this.instance],
      }
    );

    // Set outputs
    this.connectionName = this.instance.connectionName;
    this.databaseName = this.database.name;
    this.userName = pulumi.output(dbUserName);
    this.password = pulumi.secret(dbPassword.result);

    // Get IP addresses
    this.publicIp = this.instance.publicIpAddress;
    this.privateIp = this.instance.privateIpAddress;

    // Build connection string for Drizzle
    // Format: postgres://user:password@host:5432/database
    this.connectionString = pulumi.secret(
      pulumi.interpolate`postgres://${dbUserName}:${dbPassword.result}@${this.publicIp}:5432/${dbName}`
    );

    // Register outputs
    this.registerOutputs({
      connectionName: this.connectionName,
      databaseName: this.databaseName,
      userName: this.userName,
      publicIp: this.publicIp,
      privateIp: this.privateIp,
    });
  }
}
