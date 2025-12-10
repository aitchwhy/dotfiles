/**
 * Redis Adapter Tests
 *
 * Tests for the Redis implementation of Cache and Queue ports.
 */
import { describe, expect, test } from 'bun:test';
import { Effect, Layer } from 'effect';

describe('Redis Adapter', () => {
  describe('RedisCacheLive Layer', () => {
    test('exports a cache layer factory', async () => {
      const { makeRedisCacheLive } = await import('@/adapters/redis');
      expect(makeRedisCacheLive).toBeDefined();
      expect(typeof makeRedisCacheLive).toBe('function');
    });

    test('creates a cache layer with config', async () => {
      const { makeRedisCacheLive } = await import('@/adapters/redis');
      const layer = makeRedisCacheLive({
        url: 'redis://localhost:6379',
        keyPrefix: 'test:',
      });
      expect(Layer.isLayer(layer)).toBe(true);
    });
  });

  describe('RedisQueueLive Layer', () => {
    test('exports a queue layer factory', async () => {
      const { makeRedisQueueLive } = await import('@/adapters/redis');
      expect(makeRedisQueueLive).toBeDefined();
      expect(typeof makeRedisQueueLive).toBe('function');
    });

    test('creates a queue layer with config', async () => {
      const { makeRedisQueueLive } = await import('@/adapters/redis');
      const layer = makeRedisQueueLive({
        url: 'redis://localhost:6379',
        queuePrefix: 'queue:',
      });
      expect(Layer.isLayer(layer)).toBe(true);
    });
  });

  describe('Cache Service Methods', () => {
    test('get returns Effect', async () => {
      const { makeRedisCacheLive } = await import('@/adapters/redis');
      const { Cache } = await import('@/ports/cache');

      const layer = makeRedisCacheLive({
        url: 'redis://localhost:6379',
      });

      const program = Effect.gen(function* () {
        const cache = yield* Cache;
        return typeof cache.get;
      });

      const result = await Effect.runPromise(Effect.provide(program, layer));
      expect(result).toBe('function');
    });
  });

  describe('Queue Service Methods', () => {
    test('add returns Effect', async () => {
      const { makeRedisQueueLive } = await import('@/adapters/redis');
      const { Queue } = await import('@/ports/queue');

      const layer = makeRedisQueueLive({
        url: 'redis://localhost:6379',
      });

      const program = Effect.gen(function* () {
        const queue = yield* Queue;
        return typeof queue.add;
      });

      const result = await Effect.runPromise(Effect.provide(program, layer));
      expect(result).toBe('function');
    });
  });
});
