---
name: distributed-systems-patterns
description: Patterns from martinfowler.com/articles/patterns-of-distributed-systems. Use for consensus, replication, and coordination.
allowed-tools: Read, Write, Edit, Grep, Glob
---

## Distributed Systems Philosophy

Distributed systems must handle: partial failures, network partitions, clock skew, and concurrent operations. These patterns provide battle-tested solutions.

## Consensus Patterns

### Leader and Followers

**Problem:** Achieve consensus with single coordinator.

**Solution:** Elect single leader for decisions, followers replicate.

```typescript
type NodeRole = 'leader' | 'follower' | 'candidate';

type LeaderState = {
  readonly role: 'leader';
  readonly term: number;
  readonly followers: ReadonlyArray<NodeId>;
  readonly nextIndex: ReadonlyMap<NodeId, number>;
};

type FollowerState = {
  readonly role: 'follower';
  readonly term: number;
  readonly leaderId: NodeId | null;
  readonly votedFor: NodeId | null;
};

// Leader election via higher term wins
function handleRequestVote(
  state: FollowerState,
  candidateId: NodeId,
  candidateTerm: number
): { vote: boolean; newState: FollowerState } {
  if (candidateTerm > state.term) {
    return {
      vote: true,
      newState: { ...state, term: candidateTerm, votedFor: candidateId }
    };
  }
  if (candidateTerm === state.term && state.votedFor === null) {
    return {
      vote: true,
      newState: { ...state, votedFor: candidateId }
    };
  }
  return { vote: false, newState: state };
}
```

### Majority Quorum

**Problem:** Ensure progress with node failures.

**Solution:** Require majority (n/2 + 1) agreement for operations.

```typescript
type QuorumResult<T> =
  | { readonly status: 'success'; readonly value: T }
  | { readonly status: 'failed'; readonly received: number; readonly needed: number };

function waitForQuorum<T>(
  nodes: ReadonlyArray<NodeId>,
  operation: (nodeId: NodeId) => Promise<T>
): Effect.Effect<QuorumResult<T[]>, QuorumError, NodeService> {
  const quorumSize = Math.floor(nodes.length / 2) + 1;

  return Effect.gen(function* () {
    const results = yield* Effect.all(
      nodes.map(nodeId =>
        operation(nodeId).pipe(
          Effect.timeout('5 seconds'),
          Effect.option
        )
      ),
      { concurrency: 'unbounded' }
    );

    const successes = results.filter(Option.isSome).map(o => o.value);

    if (successes.length >= quorumSize) {
      return { status: 'success', value: successes };
    }
    return { status: 'failed', received: successes.length, needed: quorumSize };
  });
}
```

### Generation Clock (Epoch)

**Problem:** Distinguish between different leader terms.

**Solution:** Monotonically increasing generation number.

```typescript
type Generation = number & { readonly __brand: 'Generation' };

const Generation = {
  initial: (): Generation => 1 as Generation,
  next: (gen: Generation): Generation => (gen + 1) as Generation,
  compare: (a: Generation, b: Generation): -1 | 0 | 1 =>
    a < b ? -1 : a > b ? 1 : 0,
};

type Message = {
  readonly generation: Generation;
  readonly payload: unknown;
};

function handleMessage(
  currentGen: Generation,
  message: Message
): 'accept' | 'reject' {
  // Only accept messages from current or newer generation
  return Generation.compare(message.generation, currentGen) >= 0
    ? 'accept'
    : 'reject';
}
```

## Replication Patterns

### Write-Ahead Log (WAL)

**Problem:** Provide durability for state changes.

**Solution:** Append changes to log before applying to state.

```typescript
type LogEntry = {
  readonly index: number;
  readonly term: Generation;
  readonly command: Command;
  readonly timestamp: number;
};

type WAL = {
  readonly entries: ReadonlyArray<LogEntry>;
  readonly commitIndex: number;
  readonly lastApplied: number;
};

function appendEntry(
  wal: WAL,
  term: Generation,
  command: Command
): WAL {
  const entry: LogEntry = {
    index: wal.entries.length,
    term,
    command,
    timestamp: Date.now(),
  };
  return {
    ...wal,
    entries: [...wal.entries, entry],
  };
}

function applyCommitted(wal: WAL, state: State): { wal: WAL; state: State } {
  let newState = state;
  let lastApplied = wal.lastApplied;

  for (let i = wal.lastApplied + 1; i <= wal.commitIndex; i++) {
    newState = applyCommand(newState, wal.entries[i].command);
    lastApplied = i;
  }

  return {
    wal: { ...wal, lastApplied },
    state: newState,
  };
}
```

### High-Water Mark

**Problem:** Track which log entries are safely replicated.

**Solution:** Maintain index of highest committed entry.

```typescript
type ReplicationState = {
  readonly highWaterMark: number; // Highest committed index
  readonly matchIndex: ReadonlyMap<NodeId, number>; // Per-follower match
};

function updateHighWaterMark(
  state: ReplicationState,
  nodes: ReadonlyArray<NodeId>
): ReplicationState {
  const quorumSize = Math.floor(nodes.length / 2) + 1;

  // Find highest index replicated on quorum
  const matchIndices = Array.from(state.matchIndex.values()).sort((a, b) => b - a);
  const newHighWaterMark = matchIndices[quorumSize - 1] ?? state.highWaterMark;

  return {
    ...state,
    highWaterMark: Math.max(state.highWaterMark, newHighWaterMark),
  };
}
```

### Singular Update Queue

**Problem:** Serialize concurrent updates safely.

**Solution:** Single thread/fiber processes all state mutations.

```typescript
// Effect-TS Queue for serialized updates
const makeUpdateQueue = Effect.gen(function* () {
  const queue = yield* Queue.unbounded<StateUpdate>();
  const state = yield* Ref.make<State>(initialState);

  // Single fiber processes all updates
  yield* Effect.fork(
    Effect.forever(
      Effect.gen(function* () {
        const update = yield* Queue.take(queue);
        const currentState = yield* Ref.get(state);
        const newState = applyUpdate(currentState, update);
        yield* Ref.set(state, newState);
      })
    )
  );

  return {
    submit: (update: StateUpdate) => Queue.offer(queue, update),
    getState: () => Ref.get(state),
  };
});
```

## Versioning Patterns

### Lamport Clock

**Problem:** Order events across distributed nodes without synchronized clocks.

**Solution:** Logical timestamp incremented on every event.

```typescript
type LamportTimestamp = number & { readonly __brand: 'LamportTimestamp' };

type LamportClock = {
  readonly timestamp: LamportTimestamp;
};

const LamportClock = {
  initial: (): LamportClock => ({ timestamp: 0 as LamportTimestamp }),

  tick: (clock: LamportClock): LamportClock => ({
    timestamp: (clock.timestamp + 1) as LamportTimestamp,
  }),

  receive: (clock: LamportClock, received: LamportTimestamp): LamportClock => ({
    timestamp: (Math.max(clock.timestamp, received) + 1) as LamportTimestamp,
  }),

  // Happens-before: a -> b iff a.timestamp < b.timestamp
  // Note: converse is NOT true (concurrent events may have any ordering)
};
```

### Version Vector

**Problem:** Track causality across multiple writers.

**Solution:** Vector of per-node counters.

```typescript
type VersionVector = ReadonlyMap<NodeId, number>;

const VersionVector = {
  initial: (): VersionVector => new Map(),

  increment: (vv: VersionVector, nodeId: NodeId): VersionVector => {
    const current = vv.get(nodeId) ?? 0;
    return new Map(vv).set(nodeId, current + 1);
  },

  merge: (a: VersionVector, b: VersionVector): VersionVector => {
    const result = new Map(a);
    for (const [nodeId, count] of b) {
      result.set(nodeId, Math.max(result.get(nodeId) ?? 0, count));
    }
    return result;
  },

  compare: (a: VersionVector, b: VersionVector): 'before' | 'after' | 'concurrent' => {
    let aBeforeB = false;
    let bBeforeA = false;

    const allNodes = new Set([...a.keys(), ...b.keys()]);
    for (const nodeId of allNodes) {
      const aCount = a.get(nodeId) ?? 0;
      const bCount = b.get(nodeId) ?? 0;
      if (aCount < bCount) aBeforeB = true;
      if (bCount < aCount) bBeforeA = true;
    }

    if (aBeforeB && !bBeforeA) return 'before';
    if (bBeforeA && !aBeforeB) return 'after';
    return 'concurrent';
  },
};
```

### Hybrid Clock

**Problem:** Combine physical and logical time for better ordering.

**Solution:** Pair of physical timestamp and logical counter.

```typescript
type HybridTimestamp = {
  readonly physical: number; // Wall clock (ms)
  readonly logical: number;  // Tie-breaker
};

const HybridClock = {
  now: (lastSeen: HybridTimestamp): HybridTimestamp => {
    const physical = Date.now();
    if (physical > lastSeen.physical) {
      return { physical, logical: 0 };
    }
    return { physical: lastSeen.physical, logical: lastSeen.logical + 1 };
  },

  receive: (local: HybridTimestamp, remote: HybridTimestamp): HybridTimestamp => {
    const physical = Date.now();
    const maxPhysical = Math.max(physical, local.physical, remote.physical);

    if (maxPhysical === physical && physical > local.physical && physical > remote.physical) {
      return { physical, logical: 0 };
    }
    if (maxPhysical === local.physical && local.physical === remote.physical) {
      return { physical: maxPhysical, logical: Math.max(local.logical, remote.logical) + 1 };
    }
    if (maxPhysical === local.physical) {
      return { physical: maxPhysical, logical: local.logical + 1 };
    }
    return { physical: maxPhysical, logical: remote.logical + 1 };
  },

  compare: (a: HybridTimestamp, b: HybridTimestamp): -1 | 0 | 1 => {
    if (a.physical < b.physical) return -1;
    if (a.physical > b.physical) return 1;
    if (a.logical < b.logical) return -1;
    if (a.logical > b.logical) return 1;
    return 0;
  },
};
```

## Communication Patterns

### HeartBeat

**Problem:** Detect node failures.

**Solution:** Periodic messages; missing heartbeats indicate failure.

```typescript
type HeartbeatConfig = {
  readonly intervalMs: number;
  readonly timeoutMs: number;
};

const runHeartbeat = (
  config: HeartbeatConfig,
  sendHeartbeat: () => Effect.Effect<void, NetworkError>,
  onTimeout: () => Effect.Effect<void>
) =>
  Effect.gen(function* () {
    const lastReceived = yield* Ref.make(Date.now());

    // Send heartbeats
    yield* Effect.fork(
      Effect.forever(
        Effect.gen(function* () {
          yield* sendHeartbeat();
          yield* Effect.sleep(`${config.intervalMs} millis`);
        })
      )
    );

    // Check for timeouts
    yield* Effect.fork(
      Effect.forever(
        Effect.gen(function* () {
          yield* Effect.sleep(`${config.timeoutMs} millis`);
          const last = yield* Ref.get(lastReceived);
          if (Date.now() - last > config.timeoutMs) {
            yield* onTimeout();
          }
        })
      )
    );

    return {
      recordHeartbeat: () => Ref.set(lastReceived, Date.now()),
    };
  });
```

### Gossip Dissemination

**Problem:** Propagate information in large clusters without coordinator.

**Solution:** Random peer-to-peer information exchange.

```typescript
type GossipState<T> = {
  readonly data: ReadonlyMap<string, { value: T; version: number }>;
};

const gossipRound = <T>(
  localState: GossipState<T>,
  peers: ReadonlyArray<NodeId>,
  fanout: number = 3
): Effect.Effect<GossipState<T>, GossipError, NodeService> =>
  Effect.gen(function* () {
    // Select random subset of peers
    const selectedPeers = shuffle(peers).slice(0, fanout);

    // Exchange state with each peer
    let newState = localState;
    for (const peer of selectedPeers) {
      const peerState = yield* NodeService.exchange(peer, localState);
      newState = mergeGossipState(newState, peerState);
    }

    return newState;
  });

function mergeGossipState<T>(
  a: GossipState<T>,
  b: GossipState<T>
): GossipState<T> {
  const merged = new Map(a.data);
  for (const [key, entry] of b.data) {
    const existing = merged.get(key);
    if (!existing || entry.version > existing.version) {
      merged.set(key, entry);
    }
  }
  return { data: merged };
}
```

### Request Pipeline

**Problem:** Reduce latency by pipelining requests.

**Solution:** Send multiple requests without waiting for responses.

```typescript
type PipelinedClient = {
  readonly send: <T>(request: Request) => Effect.Effect<T, RequestError>;
  readonly flush: () => Effect.Effect<void>;
};

const makePipelinedClient = (
  maxPipelineDepth: number = 10
): Effect.Effect<PipelinedClient, never, Connection> =>
  Effect.gen(function* () {
    const pending = yield* Queue.bounded<{
      request: Request;
      resolve: (result: unknown) => void;
      reject: (error: RequestError) => void;
    }>(maxPipelineDepth);

    // Response processor
    yield* Effect.fork(
      Effect.forever(
        Effect.gen(function* () {
          const response = yield* Connection.receiveResponse();
          const { resolve, reject } = yield* Queue.take(pending);
          if (response.ok) {
            resolve(response.data);
          } else {
            reject(response.error);
          }
        })
      )
    );

    return {
      send: (request) =>
        Effect.async((resume) => {
          Queue.offer(pending, {
            request,
            resolve: (result) => resume(Effect.succeed(result)),
            reject: (error) => resume(Effect.fail(error)),
          });
          Connection.send(request);
        }),
      flush: () => Effect.void,
    };
  });
```

## Pattern Selection Guide

| Problem | Pattern |
|---------|---------|
| Need single coordinator | Leader and Followers |
| Tolerate f failures from 2f+1 nodes | Majority Quorum |
| Order events across nodes | Lamport/Hybrid Clock |
| Track concurrent updates | Version Vector |
| Durability before commit | Write-Ahead Log |
| Know what's safely replicated | High-Water Mark |
| Serialize mutations | Singular Update Queue |
| Detect failures | HeartBeat |
| Scalable propagation | Gossip Dissemination |
| Reduce round-trip latency | Request Pipeline |
