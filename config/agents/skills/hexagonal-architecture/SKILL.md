---
name: hexagonal-architecture
description: No-mock testing with service containers. Ports & Adapters for infrastructure isolation.
globs: ["**/ports/**", "**/adapters/**", "**/*.test.ts", "**/*.spec.ts", "**/factory.ts"]
alwaysApply: false
token-budget: 1500
---

# Hexagonal Architecture Testing Strategy

## Core Principle

The domain is the center. All I/O happens through ports (interfaces) implemented by adapters (concrete implementations). Tests use REAL infrastructure via service containers, never mocks.

## Absolute Constraints

### NEVER Create or Use

| Pattern | Why Forbidden |
|---------|---------------|
| `Mock*Live` classes | Bypasses real infrastructure behavior |
| `jest.mock()` | Creates hidden test doubles |
| `vi.mock()` | Creates hidden test doubles |
| `sinon.stub/mock/spy` | Runtime patching hides coupling |
| `__mocks__/` directories | Global mock pollution |
| `.mockImplementation()` | Deferred mock definition |
| `Fake*` / `Stub*` classes | Naming indicates test-only code |

### ALWAYS Use Instead

| Need | Solution |
|------|----------|
| Test database | PostgreSQL via process-compose or GitHub Actions services |
| Test blob storage | MinIO (S3-compatible) via service container |
| Test external API | Real sandbox/staging endpoint OR contract test |
| Test message queue | Real Redis/NATS via service container |
| Isolate unit | Dependency injection with real lightweight adapter |

## Layer.succeed() is DI, Not Mocking

Effect-TS dependency injection is **ALLOWED**:

```typescript
// ✅ ALLOWED - This is composition root DI
const TestDatabaseLayer = Layer.succeed(Database, testDbService);
const TestConfigLayer = Layer.succeed(Config, { baseUrl: 'http://localhost:3000' });

// Usage in tests
const program = myBusinessLogic.pipe(
  Effect.provide(TestDatabaseLayer),
  Effect.provide(TestConfigLayer)
);
```

This is dependency injection at the composition root, not runtime mocking that hides coupling. The key difference:
- **DI**: Explicit wiring visible at composition root
- **Mocking**: Hidden patching that replaces imports at runtime

## Directory Structure

```
apps/<service>/src/
├── domain/                 # Pure business logic (NO I/O)
│   ├── entities/           # Domain objects
│   ├── services/           # Domain services (stateless logic)
│   ├── events/             # Domain events
│   └── errors/             # Domain error types
├── ports/                  # Interfaces (contracts)
│   ├── inbound/            # Driving ports (what the app exposes)
│   │   └── api.port.ts     # HTTP API contract
│   └── outbound/           # Driven ports (what the app needs)
│       ├── storage.port.ts
│       ├── database.port.ts
│       └── llm.port.ts
├── adapters/               # Implementations
│   ├── inbound/            # HTTP handlers, WebSocket handlers
│   │   └── hono/           # Hono-specific adapters
│   └── outbound/           # Infrastructure adapters
│       ├── gcs-storage.adapter.ts
│       ├── s3-storage.adapter.ts
│       └── postgres.adapter.ts
└── config/                 # Wiring
    ├── container.ts        # DI container setup
    └── factories/          # Environment-aware factories
        └── storage.factory.ts
```

## Port Definition Pattern

```typescript
// ports/outbound/storage.port.ts
import { z } from 'zod';

// 1. TypeScript type is source of truth
type StorageObject = {
  readonly key: string;
  readonly bucket: string;
  readonly contentType: string;
  readonly size: number;
  readonly lastModified: Date;
};

// 2. Schema satisfies type (NEVER z.infer)
const storageObjectSchema = z.object({
  key: z.string(),
  bucket: z.string(),
  contentType: z.string(),
  size: z.number().nonnegative(),
  lastModified: z.date(),
}) satisfies z.ZodType<StorageObject>;

// 3. Port interface with typed errors
type StorageError =
  | { readonly _tag: 'NotFound'; readonly key: string }
  | { readonly _tag: 'AccessDenied'; readonly bucket: string }
  | { readonly _tag: 'NetworkError'; readonly cause: Error };

interface StoragePort {
  upload(bucket: string, key: string, data: Buffer, contentType: string): Promise<Result<StorageObject, StorageError>>;
  download(bucket: string, key: string): Promise<Result<Buffer, StorageError>>;
  delete(bucket: string, key: string): Promise<Result<void, StorageError>>;
  list(bucket: string, prefix?: string): Promise<Result<StorageObject[], StorageError>>;
}
```

## Adapter Implementation Pattern

```typescript
// adapters/outbound/gcs-storage.adapter.ts
import { Storage } from '@google-cloud/storage';
import type { StoragePort, StorageObject, StorageError } from '../../ports/outbound/storage.port';
import { Ok, Err, type Result } from '@/lib/result';

type GcsStorageConfig = {
  readonly projectId?: string;
};

export class GcsStorageAdapter implements StoragePort {
  private readonly client: Storage;

  constructor(config: GcsStorageConfig = {}) {
    this.client = new Storage(config);
  }

  async upload(
    bucket: string,
    key: string,
    data: Buffer,
    contentType: string
  ): Promise<Result<StorageObject, StorageError>> {
    try {
      const file = this.client.bucket(bucket).file(key);
      await file.save(data, { contentType, resumable: false });
      const [metadata] = await file.getMetadata();

      return Ok({
        key,
        bucket,
        contentType,
        size: Number(metadata.size),
        lastModified: new Date(metadata.updated as string),
      });
    } catch (error) {
      if (error instanceof Error && error.message.includes('403')) {
        return Err({ _tag: 'AccessDenied', bucket });
      }
      return Err({ _tag: 'NetworkError', cause: error as Error });
    }
  }

  // ... implement other methods with same Result pattern
}
```

## Factory Pattern for Environment Detection

```typescript
// config/factories/storage.factory.ts
import type { StoragePort } from '../../ports/outbound/storage.port';
import { GcsStorageAdapter } from '../../adapters/outbound/gcs-storage.adapter';
import { S3StorageAdapter } from '../../adapters/outbound/s3-storage.adapter';

type StorageEnvironment = 'gcs' | 's3' | 'minio';

function detectStorageEnvironment(): StorageEnvironment {
  if (process.env.GCS_BUCKET) return 'gcs';
  if (process.env.MINIO_ENDPOINT) return 'minio';
  if (process.env.S3_BUCKET) return 's3';
  throw new Error(
    'No storage configuration found. Set GCS_BUCKET, S3_BUCKET, or MINIO_ENDPOINT.'
  );
}

export function createStorageAdapter(env?: StorageEnvironment): StoragePort {
  const environment = env ?? detectStorageEnvironment();

  switch (environment) {
    case 'gcs':
      return new GcsStorageAdapter({ projectId: process.env.GCP_PROJECT_ID });

    case 'minio':
    case 's3':
      return new S3StorageAdapter({
        endpoint: process.env.MINIO_ENDPOINT ?? process.env.S3_ENDPOINT,
        bucket: process.env.S3_BUCKET ?? process.env.MINIO_BUCKET!,
        region: process.env.AWS_REGION ?? 'us-east-1',
        forcePathStyle: environment === 'minio',
      });
  }
}
```

## Service Container Setup

### Local Development (process-compose.yml)

```yaml
version: "0.5"
processes:
  postgres:
    command: |
      docker run --rm --name app-postgres \
        -e POSTGRES_DB=app_dev \
        -e POSTGRES_USER=app \
        -e POSTGRES_PASSWORD=app_dev \
        -p 5432:5432 \
        postgres:16-alpine
    readiness_probe:
      exec:
        command: pg_isready -h localhost -p 5432
      initial_delay_seconds: 2
      period_seconds: 1

  minio:
    command: |
      docker run --rm --name app-minio \
        -e MINIO_ROOT_USER=minioadmin \
        -e MINIO_ROOT_PASSWORD=minioadmin \
        -p 9000:9000 -p 9001:9001 \
        minio/minio server /data --console-address ":9001"
    readiness_probe:
      http_get:
        host: localhost
        port: 9000
        path: /minio/health/live
```

### CI/CD (GitHub Actions)

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: test
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      minio:
        image: minio/minio
        env:
          MINIO_ROOT_USER: minioadmin
          MINIO_ROOT_PASSWORD: minioadmin
        ports:
          - 9000:9000
        options: >-
          --health-cmd "curl -f http://localhost:9000/minio/health/live"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
```

## Integration Test Pattern

```typescript
// __tests__/integration/storage-adapter.test.ts
import { describe, test, expect, beforeAll, afterAll } from 'bun:test';
import { createStorageAdapter } from '../../config/factories/storage.factory';
import type { StoragePort } from '../../ports/outbound/storage.port';
import { isOk, isErr } from '@/lib/result';

describe('StoragePort Integration', () => {
  let storage: StoragePort;
  const testBucket = process.env.TEST_BUCKET ?? 'test-bucket';

  beforeAll(async () => {
    // Factory returns MinIO adapter in CI, GCS in staging
    // NO MOCKS - this is a real adapter talking to real infrastructure
    storage = createStorageAdapter();
  });

  afterAll(async () => {
    // Cleanup test artifacts
    const listResult = await storage.list(testBucket, 'test-');
    if (isOk(listResult)) {
      await Promise.all(
        listResult.data.map((obj) => storage.delete(testBucket, obj.key))
      );
    }
  });

  test('upload returns StorageObject with correct metadata', async () => {
    const key = `test-${Date.now()}-upload.txt`;
    const content = Buffer.from('integration test content');

    const result = await storage.upload(testBucket, key, content, 'text/plain');

    expect(isOk(result)).toBe(true);
    if (isOk(result)) {
      expect(result.data.key).toBe(key);
      expect(result.data.bucket).toBe(testBucket);
      expect(result.data.size).toBe(content.length);
    }
  });

  test('download returns uploaded content exactly', async () => {
    const key = `test-${Date.now()}-roundtrip.txt`;
    const content = Buffer.from('roundtrip test');

    await storage.upload(testBucket, key, content, 'text/plain');
    const result = await storage.download(testBucket, key);

    expect(isOk(result)).toBe(true);
    if (isOk(result)) {
      expect(result.data.toString()).toBe('roundtrip test');
    }
  });

  test('download non-existent key returns NotFound error', async () => {
    const result = await storage.download(testBucket, 'non-existent-key-12345');

    expect(isErr(result)).toBe(true);
    if (isErr(result)) {
      expect(result.error._tag).toBe('NotFound');
    }
  });
});
```

## Environment Matrix

| Environment | Database | Blob Storage | Detection Variable |
|-------------|----------|--------------|-------------------|
| Local Dev | PostgreSQL (Docker) | MinIO | `MINIO_ENDPOINT` |
| CI/CD | PostgreSQL (service) | MinIO (service) | `MINIO_ENDPOINT` |
| Staging | Cloud SQL | GCS | `GCS_BUCKET` |
| Production | Cloud SQL | GCS | `GCS_BUCKET` |

## Anti-Patterns to Reject

```typescript
// ❌ REJECT: Mock implementation class
class MockStorageLive implements StoragePort {
  private store = new Map<string, Buffer>();
  // ...
}

// ❌ REJECT: jest.mock usage
jest.mock('@google-cloud/storage');

// ❌ REJECT: Inline test doubles
const fakeStorage = { upload: vi.fn(), download: vi.fn() };

// ❌ REJECT: Sinon stubs
const storageStub = sinon.stub(storage, 'upload').resolves({});

// ✅ ACCEPT: Factory with real adapter
const storage = createStorageAdapter(); // Returns real MinIO in tests

// ✅ ACCEPT: Effect-TS Layer DI
const TestLayer = Layer.succeed(Database, realTestDbService);
```

## Validation

Before committing adapter code, verify:

```bash
# Start service containers
process-compose up -d

# Run integration tests
bun test --grep "Integration"

# Check no mock patterns exist
rg "Mock[A-Z].*Live|jest\.mock|vi\.mock" src/
```
