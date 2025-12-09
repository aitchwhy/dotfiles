/**
 * Queue Service Component
 *
 * Creates a Pub/Sub topic with subscriptions for async messaging.
 * Supports both push and pull delivery patterns.
 */
import * as pulumi from '@pulumi/pulumi';
import * as gcp from '@pulumi/gcp';
import { SignetComponent, type SignetComponentArgs } from './base';

// =============================================================================
// COMPONENT ARGS
// =============================================================================

export type SubscriptionConfig = {
  /** Subscription name suffix */
  readonly name: string;

  /** Push endpoint URL (omit for pull subscription) */
  readonly pushEndpoint?: pulumi.Input<string>;

  /** Acknowledgement deadline in seconds (default: 60) */
  readonly ackDeadlineSeconds?: number;

  /** Message retention duration in seconds (default: 604800 = 7 days) */
  readonly messageRetentionSeconds?: number;

  /** Retry policy minimum backoff in seconds */
  readonly retryMinBackoffSeconds?: number;

  /** Retry policy maximum backoff in seconds */
  readonly retryMaxBackoffSeconds?: number;

  /** Dead letter topic (for failed messages) */
  readonly deadLetterTopic?: pulumi.Input<string>;

  /** Max delivery attempts before dead letter (default: 5) */
  readonly maxDeliveryAttempts?: number;

  /** Filter expression for message filtering */
  readonly filter?: string;
};

export type QueueServiceArgs = SignetComponentArgs & {
  /** GCP project ID */
  readonly projectId: pulumi.Input<string>;

  /** Message retention duration in seconds (default: 86400 = 1 day) */
  readonly messageRetentionSeconds?: number;

  /** Subscriptions to create */
  readonly subscriptions?: readonly SubscriptionConfig[];

  /** Enable message ordering */
  readonly enableMessageOrdering?: boolean;

  /** Schema for message validation */
  readonly schema?: {
    name: string;
    type: 'AVRO' | 'PROTOCOL_BUFFER';
    definition: string;
  };
};

// =============================================================================
// COMPONENT
// =============================================================================

/**
 * QueueService - Pub/Sub topic with subscriptions
 *
 * Features:
 * - Push and pull subscription support
 * - Dead letter queue configuration
 * - Message ordering support
 * - Retry policies
 * - Message filtering
 */
export class QueueService extends SignetComponent {
  /** The Pub/Sub topic */
  public readonly topic: gcp.pubsub.Topic;

  /** Topic name */
  public readonly topicName: pulumi.Output<string>;

  /** Topic ID for publishing */
  public readonly topicId: pulumi.Output<string>;

  /** Created subscriptions */
  public readonly subscriptions: gcp.pubsub.Subscription[];

  /** Schema (if configured) */
  public readonly schema?: gcp.pubsub.Schema;

  constructor(
    name: string,
    args: QueueServiceArgs,
    opts?: pulumi.ComponentResourceOptions
  ) {
    super('signet:gcp:QueueService', name, args, opts);

    const defaultOpts = this.defaultResourceOptions();

    // Create schema if provided
    if (args.schema) {
      this.schema = new gcp.pubsub.Schema(
        `${name}-schema`,
        {
          name: this.shortResourceName(`${name}-schema`),
          project: args.projectId,
          type: args.schema.type,
          definition: args.schema.definition,
        },
        defaultOpts
      );
    }

    // Create topic - conditionally include optional properties
    const topicArgs: gcp.pubsub.TopicArgs = {
      name: this.shortResourceName(name),
      project: args.projectId,
      labels: this.labels,
      messageRetentionDuration: `${args.messageRetentionSeconds ?? 86400}s`,
    };
    if (this.schema) {
      topicArgs.schemaSettings = {
        schema: this.schema.id,
        encoding: 'JSON',
      };
    }

    this.topic = new gcp.pubsub.Topic(
      `${name}-topic`,
      topicArgs,
      defaultOpts
    );

    this.topicName = this.topic.name;
    this.topicId = this.topic.id;

    // Create subscriptions
    this.subscriptions = (args.subscriptions ?? []).map((sub) => {
      const subscriptionName = `${name}-${sub.name}`;

      // Build subscription args conditionally to avoid exactOptionalPropertyTypes issues
      const subArgs: gcp.pubsub.SubscriptionArgs = {
        name: this.shortResourceName(subscriptionName),
        topic: this.topic.name,
        project: args.projectId,
        labels: {
          ...this.labels,
          subscription: sub.name,
        },
        ackDeadlineSeconds: sub.ackDeadlineSeconds ?? 60,
        messageRetentionDuration: `${sub.messageRetentionSeconds ?? 604800}s`,
        enableMessageOrdering: args.enableMessageOrdering ?? false,
        // Expiration policy (never expire for active subscriptions)
        expirationPolicy: {
          ttl: '', // Empty string = never expire
        },
      };

      // Optional filter
      if (sub.filter) {
        subArgs.filter = sub.filter;
      }

      // Push config (if endpoint provided)
      if (sub.pushEndpoint) {
        subArgs.pushConfig = {
          pushEndpoint: sub.pushEndpoint,
          attributes: {
            'x-goog-version': 'v1',
          },
          // OIDC authentication for Cloud Run endpoints
          oidcToken: {
            serviceAccountEmail: pulumi.interpolate`${args.projectId}@appspot.gserviceaccount.com`,
          },
        };
      }

      // Retry policy
      if (sub.retryMinBackoffSeconds || sub.retryMaxBackoffSeconds) {
        subArgs.retryPolicy = {
          minimumBackoff: `${sub.retryMinBackoffSeconds ?? 10}s`,
          maximumBackoff: `${sub.retryMaxBackoffSeconds ?? 600}s`,
        };
      }

      // Dead letter policy
      if (sub.deadLetterTopic) {
        subArgs.deadLetterPolicy = {
          deadLetterTopic: sub.deadLetterTopic,
          maxDeliveryAttempts: sub.maxDeliveryAttempts ?? 5,
        };
      }

      return new gcp.pubsub.Subscription(
        subscriptionName,
        subArgs,
        defaultOpts
      );
    });

    // Register outputs
    this.registerOutputs({
      topicName: this.topicName,
      topicId: this.topicId,
      subscriptionCount: this.subscriptions.length,
    });
  }

  /**
   * Get subscription by name
   */
  public getSubscription(name: string): gcp.pubsub.Subscription | undefined {
    return this.subscriptions.find((s) =>
      s.name.apply((n) => n.includes(name))
    );
  }
}
