# Ember: Family Voices — Specification

> **Single Source of Truth** for product and engineering decisions.
> Version: 1.1.0 | Created: 2025-11-25 | Frozen Until: 2025-02-25

---

## Document Guide

| Audience | Read Sections |
|----------|---------------|
| Co-founder / Product | Part 1 only |
| Engineers / AI Agents | Parts 1–4 |
| New Contributors | Parts 1–2, then 3–4 as needed |

**Conventions:**
- `MUST` — Required, no exceptions
- `SHOULD` — Strongly recommended
- `MAY` — Optional

---

# Part 1: Product Specification

## 1.1 Vision

**Ember** is a voice memory platform that helps families preserve stories across generations. Creators invite family members to record memories with an AI interviewer that guides the conversation.

**Core Insight:** Social triggers (family members prompting each other) achieve 60–70% completion rates versus 15–20% for self-initiated recording.

## 1.2 Users

| Persona | Description | Goal |
|---------|-------------|------|
| **Creator** | Adult (25–50) preserving family stories | Create invites, listen to recordings |
| **Storyteller** | Family member (50–85) with stories to share | Record memories via phone/browser |

## 1.3 MVP Scope

**Four features only:**

1. **Invite Creation** — Creator generates a shareable link
2. **Recording** — Storyteller talks to AI interviewer via link
3. **Storage** — Audio securely stored
4. **Playback** — Creator listens to recordings

**Out of Scope:**
- Storyteller accounts (link-only access)
- Transcription/highlights
- Multiple recordings per invite
- Native mobile apps

## 1.4 User Flows

### Feature: Invite Creation

```gherkin
Feature: Creator sends invite to family member

  Scenario: Create new invite
    Given I am logged in
    When I tap "New Invite"
    And I enter name "Grandma Rose"
    And I select relationship "Grandparent"
    And I tap "Create"
    Then I see a shareable link
    And the invite expires in 7 days

  Scenario: View my invites
    Given I am logged in
    When I view "My Invites"
    Then I see all invites with status
    And completed invites show "Listen" button
```

### Feature: Recording

```gherkin
Feature: Storyteller records a memory

  Scenario: Start recording session
    Given I opened a valid invite link
    When I tap "Start Recording"
    And I allow microphone access
    Then I connect to the AI interviewer
    And I hear a warm greeting

  Scenario: Conversation flow
    Given I am connected to the AI
    When I share my story
    Then the AI listens and asks follow-up questions
    When I say "I'm done" or stay silent 30 seconds
    Then the recording ends and is saved

  Scenario: Recording saved
    Given my session ended
    Then I see "Memory saved!"
    And the Creator is notified
```

### Feature: Playback

```gherkin
Feature: Creator listens to recordings

  Scenario: Listen to recording
    Given an invite has a completed recording
    When I tap "Listen"
    Then I see an audio player with duration and progress
```

## 1.5 Success Metrics

| Metric | Target |
|--------|--------|
| Invite → Recording Completion | >50% |
| Average Recording Duration | >3 min |
| Recording Listen Rate | >80% |
| Time to First Recording | <5 min |

## 1.6 Constraints

| Constraint | Rationale |
|------------|-----------|
| Web-only | Ships faster, works everywhere |
| English-only | Simplest AI config |
| 1 recording per invite | Clear mental model |
| 7-day invite expiry | Creates urgency |
| 30-minute max recording | Cost control |

---

# Part 2: Engineering Specification

## 2.1 Principles

1. **Own the Build** — Language-native tools, explicit over implicit
2. **Own the Data** — Portable schemas, standard protocols
3. **Own the Contracts** — Shared types via Zod schemas
4. **Minimize Vendor Surface** — Every vendor behind abstraction
5. **Ship Incrementally** — Working software over documentation

## 2.2 Technology Stack

**All versions frozen until 2025-02-25.**

| Layer | Technology | Version | Rationale |
|-------|------------|---------|-----------|
| Runtime | Bun | 1.3.3 | Workspaces, native TS, fast |
| Language | TypeScript | 5.9.x | Strict mode everywhere |
| Validation | Zod | 3.25.x | Single schema source of truth |
| Frontend | React | 19.x | Stable, hooks |
| Build | Vite | 7.x | Fast, portable output |
| Routing | TanStack Router | 1.x | Type-safe, file-based |
| Data | TanStack Query | 5.x | Caching, mutations |
| Styling | Tailwind CSS | 4.x | Utility-first, no runtime |
| API | HonoJS | 4.x | Multi-runtime, small |
| ORM | Drizzle | 0.44.x | SQL-first, edge-compatible |
| Database | Neon Postgres | Latest | Serverless, branching |
| Auth | BetterAuth | Latest | Self-hosted, phone OTP |
| Storage | Cloudflare R2 | Latest | Zero egress, S3-compatible |
| Realtime | LiveKit Cloud | Latest | WebRTC, agent hosting, egress |
| AI Agent | @livekit/agents | 1.0.x | TypeScript voice pipeline |

### Infrastructure

| Service | Provider | Portability |
|---------|----------|-------------|
| Database | Neon | Any Postgres |
| Auth | BetterAuth | Self-hosted |
| Storage | Cloudflare R2 | Any S3-compatible |
| Realtime | LiveKit Cloud | Self-hosted LiveKit |
| Frontend | Vercel | Any static host |
| API | Cloudflare Workers | Bun/Node anywhere |
| Agent | LiveKit Cloud | Self-hosted agent workers |

## 2.3 Monorepo Structure

```
ember/
├── .github/workflows/
│   ├── ci.yml
│   └── deploy.yml
├── .env.example
├── .env.local                    # gitignored
├── package.json                  # workspace root
├── tsconfig.json                 # base config
├── biome.json
├── tailwind.config.ts
├── SPEC.md
├── README.md
│
├── apps/
│   ├── web/                      # React SPA
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   ├── vite.config.ts
│   │   ├── index.html
│   │   └── src/
│   │       ├── main.tsx
│   │       ├── routes/           # TanStack Router
│   │       │   ├── __root.tsx
│   │       │   ├── index.tsx
│   │       │   ├── invites.tsx
│   │       │   ├── invites.new.tsx
│   │       │   └── invite.$token.tsx
│   │       ├── components/
│   │       ├── hooks/
│   │       └── lib/
│   │
│   ├── api/                      # HonoJS API
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   ├── wrangler.toml
│   │   ├── drizzle.config.ts
│   │   └── src/
│   │       ├── index.ts
│   │       ├── routes/
│   │       │   ├── auth.ts
│   │       │   ├── invites.ts
│   │       │   ├── recordings.ts
│   │       │   └── webhooks.ts
│   │       ├── db/
│   │       │   ├── schema.ts
│   │       │   └── client.ts
│   │       ├── lib/
│   │       │   ├── auth.ts
│   │       │   ├── storage.ts
│   │       │   └── livekit.ts
│   │       └── middleware/
│   │
│   └── agent/                    # LiveKit Voice Agent (TypeScript)
│       ├── package.json
│       ├── tsconfig.json
│       ├── livekit.toml
│       ├── Dockerfile
│       └── src/
│           ├── index.ts          # Agent entrypoint
│           └── prompts.ts
│
├── packages/
│   └── domain/                   # Shared Zod schemas
│       ├── package.json
│       ├── tsconfig.json
│       └── src/
│           ├── index.ts
│           └── schemas.ts
│
└── e2e/                          # Playwright E2E tests
    ├── playwright.config.ts
    └── tests/
        └── invite-flow.spec.ts
```

## 2.4 Data Model

### Entity Relationship

```
User 1──* Invite 1──1 Recording
```

A **User** creates **Invites**. Each Invite produces at most one **Recording**.

### Database Schema

```sql
-- Custom types
CREATE TYPE invite_status AS ENUM ('pending', 'recording', 'completed', 'expired');

-- Users (authenticated creators)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Invites (contains person info inline)
CREATE TABLE invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token VARCHAR(32) UNIQUE NOT NULL,
  creator_id UUID NOT NULL REFERENCES users(id),
  
  -- Person info (denormalized for MVP simplicity)
  person_name VARCHAR(100) NOT NULL,
  person_relationship VARCHAR(20) NOT NULL,
  
  -- State
  status invite_status NOT NULL DEFAULT 'pending',
  room_name VARCHAR(100),            -- LiveKit room (set when recording starts)
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Recordings (one per invite max)
CREATE TABLE recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invite_id UUID UNIQUE NOT NULL REFERENCES invites(id),  -- UNIQUE enforces 1:1
  storage_key TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL,
  size_bytes BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_invites_token ON invites(token);
CREATE INDEX idx_invites_creator ON invites(creator_id);
CREATE INDEX idx_invites_status ON invites(status) WHERE status = 'pending';
```

### Drizzle Schema

```typescript
// apps/api/src/db/schema.ts
import { pgTable, uuid, varchar, timestamp, bigint, integer, pgEnum, index } from "drizzle-orm/pg-core";

export const inviteStatusEnum = pgEnum("invite_status", ["pending", "recording", "completed", "expired"]);

export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  phone: varchar("phone", { length: 20 }).unique().notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
});

export const invites = pgTable("invites", {
  id: uuid("id").primaryKey().defaultRandom(),
  token: varchar("token", { length: 32 }).unique().notNull(),
  creatorId: uuid("creator_id").notNull().references(() => users.id),
  personName: varchar("person_name", { length: 100 }).notNull(),
  personRelationship: varchar("person_relationship", { length: 20 }).notNull(),
  status: inviteStatusEnum("status").notNull().default("pending"),
  roomName: varchar("room_name", { length: 100 }),
  expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
}, (table) => [
  index("idx_invites_creator").on(table.creatorId),
]);

export const recordings = pgTable("recordings", {
  id: uuid("id").primaryKey().defaultRandom(),
  inviteId: uuid("invite_id").unique().notNull().references(() => invites.id),
  storageKey: varchar("storage_key", { length: 500 }).notNull(),
  durationSeconds: integer("duration_seconds").notNull(),
  sizeBytes: bigint("size_bytes", { mode: "number" }).notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});
```

## 2.5 API Specification

**Base URL:** `https://api.ember.app` | `http://localhost:8787`

### Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /api/auth/otp/send | None | Send OTP to phone |
| POST | /api/auth/otp/verify | None | Verify OTP, get session |
| POST | /api/auth/logout | Cookie | End session |
| POST | /api/invites | Cookie | Create invite |
| GET | /api/invites | Cookie | List creator's invites |
| GET | /api/invites/:token | None | Get invite by token (public) |
| POST | /api/invites/:token/join | None | Get LiveKit token for recording |
| GET | /api/recordings/:id/url | Cookie | Get signed playback URL |
| POST | /api/webhooks/livekit | Signature | LiveKit event webhook |

### Request/Response Schemas

```typescript
// packages/domain/src/schemas.ts
import { z } from "zod";

// === Enums ===
export const InviteStatus = z.enum(["pending", "recording", "completed", "expired"]);
export const Relationship = z.enum(["parent", "grandparent", "sibling", "other"]);

// === Auth ===
export const SendOtpRequest = z.object({
  phone: z.string().regex(/^\+[1-9]\d{1,14}$/, "E.164 format required"),
});

export const VerifyOtpRequest = z.object({
  phone: z.string().regex(/^\+[1-9]\d{1,14}$/),
  code: z.string().length(6),
});

// === Invites ===
export const CreateInviteRequest = z.object({
  personName: z.string().min(1).max(100),
  personRelationship: Relationship,
});

export const CreateInviteResponse = z.object({
  id: z.string().uuid(),
  token: z.string().length(32),
  inviteUrl: z.string().url(),
  expiresAt: z.string().datetime(),
});

export const InviteResponse = z.object({
  id: z.string().uuid(),
  token: z.string(),
  personName: z.string(),
  personRelationship: Relationship,
  status: InviteStatus,
  expiresAt: z.string().datetime(),
  createdAt: z.string().datetime(),
  recording: z.object({
    id: z.string().uuid(),
    durationSeconds: z.number(),
  }).nullable(),
});

export const JoinResponse = z.object({
  token: z.string(),
  roomName: z.string(),
  serverUrl: z.string().url(),
});

// === Recordings ===
export const RecordingUrlResponse = z.object({
  url: z.string().url(),
  expiresAt: z.string().datetime(),
});

// === Errors ===
export const ErrorResponse = z.object({
  error: z.object({
    code: z.string(),
    message: z.string(),
  }),
});

// Export types
export type SendOtpRequest = z.infer<typeof SendOtpRequest>;
export type VerifyOtpRequest = z.infer<typeof VerifyOtpRequest>;
export type CreateInviteRequest = z.infer<typeof CreateInviteRequest>;
export type CreateInviteResponse = z.infer<typeof CreateInviteResponse>;
export type InviteResponse = z.infer<typeof InviteResponse>;
export type JoinResponse = z.infer<typeof JoinResponse>;
export type ErrorResponse = z.infer<typeof ErrorResponse>;
```

### Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| `INVALID_INPUT` | 400 | Request validation failed |
| `UNAUTHORIZED` | 401 | Missing or invalid session |
| `FORBIDDEN` | 403 | Not allowed to access resource |
| `NOT_FOUND` | 404 | Resource doesn't exist |
| `INVITE_EXPIRED` | 410 | Invite past expiration |
| `INVITE_USED` | 409 | Invite already has recording |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

### CORS Configuration

```typescript
// apps/api/src/index.ts
import { cors } from "hono/cors";

app.use("*", cors({
  origin: [
    "http://localhost:3000",
    "https://ember.app",
    "https://*.vercel.app",
  ],
  credentials: true,
  allowMethods: ["GET", "POST", "OPTIONS"],
  allowHeaders: ["Content-Type"],
}));
```

## 2.6 Recording Architecture

### How Recording Works

1. **Storyteller joins** → Frontend calls `POST /api/invites/:token/join`
2. **API creates LiveKit room** → Returns token, room name, server URL
3. **Frontend connects to LiveKit** → Storyteller joins as participant
4. **Agent auto-joins** → LiveKit Cloud dispatches agent to room
5. **Conversation happens** → Agent interviews storyteller
6. **Session ends** → Agent or storyteller ends session
7. **LiveKit Egress** → Automatic room composite recording to R2
8. **Webhook received** → `POST /api/webhooks/livekit` with recording info
9. **Recording saved** → API creates recording row, updates invite status

### LiveKit Room Configuration

```typescript
// apps/api/src/lib/livekit.ts
import { RoomServiceClient, AccessToken, RoomEgress } from "livekit-server-sdk";

const roomService = new RoomServiceClient(
  process.env.LIVEKIT_URL!,
  process.env.LIVEKIT_API_KEY!,
  process.env.LIVEKIT_API_SECRET!
);

export async function createRecordingRoom(inviteToken: string): Promise<{
  roomName: string;
  participantToken: string;
}> {
  const roomName = `ember-${inviteToken}`;
  
  // Create room with auto-recording enabled
  await roomService.createRoom({
    name: roomName,
    emptyTimeout: 300, // 5 min
    maxParticipants: 2, // storyteller + agent
    egress: {
      room: {
        roomName,
        fileOutputs: [{
          fileType: "mp4",
          filepath: `recordings/${inviteToken}/{room_name}-{time}`,
          s3: {
            bucket: process.env.R2_BUCKET!,
            region: "auto",
            endpoint: process.env.R2_ENDPOINT!,
            accessKey: process.env.R2_ACCESS_KEY_ID!,
            secret: process.env.R2_SECRET_ACCESS_KEY!,
          },
        }],
        audioOnly: true,
      },
    },
  });
  
  // Generate participant token
  const token = new AccessToken(
    process.env.LIVEKIT_API_KEY!,
    process.env.LIVEKIT_API_SECRET!,
    { identity: "storyteller", ttl: 1800 }
  );
  token.addGrant({ roomJoin: true, room: roomName });
  
  return {
    roomName,
    participantToken: await token.toJwt(),
  };
}
```

### Webhook Handler

```typescript
// apps/api/src/routes/webhooks.ts
import { Hono } from "hono";
import { WebhookReceiver } from "livekit-server-sdk";
import { db } from "../db/client";
import { invites, recordings } from "../db/schema";
import { eq } from "drizzle-orm";

const receiver = new WebhookReceiver(
  process.env.LIVEKIT_API_KEY!,
  process.env.LIVEKIT_API_SECRET!
);

export const webhooksRouter = new Hono();

webhooksRouter.post("/livekit", async (c) => {
  const body = await c.req.text();
  const auth = c.req.header("Authorization") ?? "";
  
  const event = await receiver.receive(body, auth);
  
  if (event.event === "egress_ended" && event.egressInfo) {
    const egress = event.egressInfo;
    const roomName = egress.roomName;
    
    // Extract invite token from room name (ember-{token})
    const inviteToken = roomName.replace("ember-", "");
    
    // Find invite by token
    const [invite] = await db
      .select()
      .from(invites)
      .where(eq(invites.token, inviteToken))
      .limit(1);
    
    if (!invite) {
      return c.json({ error: "Invite not found" }, 404);
    }
    
    // Extract file info from egress
    const file = egress.fileResults?.[0];
    if (!file) {
      return c.json({ error: "No file in egress" }, 400);
    }
    
    // Create recording
    await db.insert(recordings).values({
      inviteId: invite.id,
      storageKey: file.filename,
      durationSeconds: Math.round((egress.endedAt - egress.startedAt) / 1_000_000_000),
      sizeBytes: Number(file.size),
    });
    
    // Update invite status
    await db
      .update(invites)
      .set({ status: "completed" })
      .where(eq(invites.id, invite.id));
  }
  
  return c.json({ received: true });
});
```

## 2.7 Agent Implementation

### TypeScript Agent

```typescript
// apps/agent/src/index.ts
import {
  type JobContext,
  type JobProcess,
  WorkerOptions,
  cli,
  defineAgent,
  llm,
  voice,
} from "@livekit/agents";
import * as openai from "@livekit/agents-plugin-openai";
import * as silero from "@livekit/agents-plugin-silero";
import { SYSTEM_PROMPT } from "./prompts";

export default defineAgent({
  prewarm: async (proc: JobProcess) => {
    proc.userData.vad = await silero.VAD.load();
  },
  
  entry: async (ctx: JobContext) => {
    await ctx.connect();
    
    const agent = new voice.Agent({
      instructions: SYSTEM_PROMPT,
      vad: ctx.proc.userData.vad,
      stt: new openai.STT(),
      llm: new openai.LLM({ model: "gpt-4o" }),
      tts: new openai.TTS({ voice: "alloy" }),
    });
    
    const session = new voice.AgentSession({ agent });
    
    await session.start(ctx.room);
    
    // Greet the user
    await session.generateReply({
      instructions: "Greet the user warmly and ask what memory they'd like to share today.",
    });
  },
});

if (import.meta.main) {
  cli.runApp(new WorkerOptions({ agent: import.meta.url }));
}
```

### Agent Prompts

```typescript
// apps/agent/src/prompts.ts
export const SYSTEM_PROMPT = `You are a warm, patient interviewer helping someone record memories for their family.

GUIDELINES:
- Be genuinely curious and encouraging
- Ask open-ended questions about life experiences
- Listen without interrupting
- Ask thoughtful follow-up questions
- Keep your responses brief (1-2 sentences)
- If they seem done, ask "Is there anything else you'd like to add?"
- After 2-3 stories, thank them warmly and say goodbye

TOPICS TO EXPLORE:
- Childhood memories
- Family traditions
- Life lessons learned
- Favorite experiences
- Advice for younger generations

Never mention that you are an AI. Speak naturally as an interviewer.`;
```

### Agent package.json

```json
{
  "name": "@ember/agent",
  "type": "module",
  "scripts": {
    "dev": "lk agent dev",
    "deploy": "lk agent deploy"
  },
  "dependencies": {
    "@livekit/agents": "^1.0.5",
    "@livekit/agents-plugin-openai": "^1.0.5",
    "@livekit/agents-plugin-silero": "^1.0.5"
  }
}
```

## 2.8 Code Patterns

### API Route with Validation

```typescript
// apps/api/src/routes/invites.ts
import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { CreateInviteRequest, ErrorResponse } from "@ember/domain";
import { requireAuth } from "../middleware/auth";
import { db } from "../db/client";
import { invites } from "../db/schema";
import { generateToken } from "../lib/utils";

export const invitesRouter = new Hono();

invitesRouter.post(
  "/",
  requireAuth,
  zValidator("json", CreateInviteRequest),
  async (c) => {
    const user = c.get("user");
    const body = c.req.valid("json");
    
    const token = generateToken(32);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    
    const [invite] = await db.insert(invites).values({
      token,
      creatorId: user.id,
      personName: body.personName,
      personRelationship: body.personRelationship,
      expiresAt,
    }).returning();
    
    return c.json({
      id: invite.id,
      token: invite.token,
      inviteUrl: `${process.env.APP_URL}/invite/${invite.token}`,
      expiresAt: invite.expiresAt.toISOString(),
    });
  }
);
```

### React Component

```typescript
// apps/web/src/components/InviteCard.tsx
import type { InviteResponse } from "@ember/domain";

type Props = {
  invite: InviteResponse;
  onListen?: () => void;
};

export function InviteCard({ invite, onListen }: Props) {
  const isCompleted = invite.status === "completed";
  const isExpired = invite.status === "expired";
  
  return (
    <div className="rounded-lg border p-4">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="font-medium">{invite.personName}</h3>
          <p className="text-sm text-gray-500">{invite.personRelationship}</p>
        </div>
        
        <StatusBadge status={invite.status} />
      </div>
      
      {isCompleted && invite.recording && (
        <button
          onClick={onListen}
          className="mt-3 w-full rounded bg-blue-600 px-4 py-2 text-white"
        >
          Listen ({formatDuration(invite.recording.durationSeconds)})
        </button>
      )}
      
      {isExpired && (
        <p className="mt-3 text-sm text-gray-400">Invite expired</p>
      )}
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const colors: Record<string, string> = {
    pending: "bg-yellow-100 text-yellow-800",
    recording: "bg-blue-100 text-blue-800",
    completed: "bg-green-100 text-green-800",
    expired: "bg-gray-100 text-gray-500",
  };
  
  return (
    <span className={`rounded-full px-2 py-1 text-xs ${colors[status]}`}>
      {status}
    </span>
  );
}

function formatDuration(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, "0")}`;
}
```

### Custom Hook

```typescript
// apps/web/src/hooks/useInvites.ts
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import type { InviteResponse, CreateInviteRequest, CreateInviteResponse } from "@ember/domain";
import { api } from "../lib/api";

export function useInvites() {
  return useQuery({
    queryKey: ["invites"],
    queryFn: () => api.get<InviteResponse[]>("/invites"),
  });
}

export function useCreateInvite() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: (data: CreateInviteRequest) => 
      api.post<CreateInviteResponse>("/invites", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invites"] });
    },
  });
}
```

## 2.9 Environment Variables

```bash
# .env.example

# === Database ===
DATABASE_URL=postgresql://user:pass@host/db?sslmode=require

# === LiveKit ===
LIVEKIT_API_KEY=
LIVEKIT_API_SECRET=
LIVEKIT_URL=wss://your-project.livekit.cloud

# === Storage (Cloudflare R2) ===
R2_ENDPOINT=https://xxx.r2.cloudflarestorage.com
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET=ember-recordings

# === OpenAI ===
OPENAI_API_KEY=sk-xxx

# === Twilio (SMS) ===
TWILIO_ACCOUNT_SID=ACxxx
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=+1234567890

# === Application ===
APP_URL=http://localhost:3000
API_URL=http://localhost:8787
NODE_ENV=development
```

## 2.10 Testing Strategy

| Type | Location | Runner | Scope |
|------|----------|--------|-------|
| Unit | `**/*.test.ts` | `bun test` | Schemas, utils, pure functions |
| Integration | `apps/*/tests/` | `bun test` | DB queries, API routes |
| E2E | `e2e/tests/` | Playwright | Full user flows |

### Test Example

```typescript
// packages/domain/src/schemas.test.ts
import { describe, test, expect } from "bun:test";
import { CreateInviteRequest } from "./schemas";

describe("CreateInviteRequest", () => {
  test("accepts valid input", () => {
    const result = CreateInviteRequest.safeParse({
      personName: "Grandma Rose",
      personRelationship: "grandparent",
    });
    expect(result.success).toBe(true);
  });
  
  test("rejects empty name", () => {
    const result = CreateInviteRequest.safeParse({
      personName: "",
      personRelationship: "grandparent",
    });
    expect(result.success).toBe(false);
  });
  
  test("rejects invalid relationship", () => {
    const result = CreateInviteRequest.safeParse({
      personName: "John",
      personRelationship: "cousin",
    });
    expect(result.success).toBe(false);
  });
});
```

## 2.11 Deployment

| Service | Platform | Command |
|---------|----------|---------|
| Frontend | Vercel | Auto via Git push |
| API | Cloudflare Workers | `cd apps/api && bunx wrangler deploy` |
| Agent | LiveKit Cloud | `cd apps/agent && lk agent deploy` |

### Rate Limiting

```typescript
// apps/api/src/middleware/rateLimit.ts
import { rateLimiter } from "hono-rate-limiter";

// 100 requests per minute per IP
export const apiRateLimit = rateLimiter({
  windowMs: 60_000,
  limit: 100,
  keyGenerator: (c) => c.req.header("CF-Connecting-IP") ?? "unknown",
});

// 5 OTP requests per hour per phone
export const otpRateLimit = rateLimiter({
  windowMs: 60 * 60_000,
  limit: 5,
  keyGenerator: async (c) => {
    const body = await c.req.json();
    return body.phone ?? "unknown";
  },
});
```

---

# Part 3: Architecture Decision Records

## ADR-001: Monorepo with apps/ and packages/

**Status:** Accepted

**Decision:** Use `apps/` for deployable units, `packages/` for shared code.

**Rationale:** Clear separation, standard convention (matches Turborepo/Nx), Bun workspaces native support.

**Consequences:** Workspace imports (`@ember/domain`), per-app configs.

---

## ADR-002: Vite + React over Next.js

**Status:** Accepted

**Decision:** Use Vite + React SPA.

**Rationale:**
- Portable static output (deploy anywhere)
- No framework magic (predictable)
- API is separate service (no need for full-stack)

**Consequences:** Manual routing (TanStack Router), no SSR.

---

## ADR-003: HonoJS for API

**Status:** Accepted

**Decision:** Use HonoJS.

**Rationale:**
- Multi-runtime (Bun, Node, Workers)
- Small (<12KB)
- Excellent Zod integration

**Consequences:** Smaller ecosystem than Express.

---

## ADR-004: Drizzle ORM over Prisma

**Status:** Accepted

**Decision:** Use Drizzle ORM.

**Rationale:**
- SQL-first (transparent queries)
- Tiny bundle (~7KB vs Prisma's 2MB)
- Edge-compatible (no binaries)

**Consequences:** Less abstraction, need SQL knowledge.

---

## ADR-005: BetterAuth for Authentication

**Status:** Accepted

**Decision:** Use BetterAuth (self-hosted).

**Rationale:**
- Runs in our API (no external service)
- Uses our Postgres
- Full control over phone OTP flow

**Consequences:** Must handle security ourselves.

---

## ADR-006: LiveKit Cloud for WebRTC and Agent

**Status:** Accepted

**Decision:** Use LiveKit Cloud with managed agent hosting.

**Rationale:**
- Integrated WebRTC + agent hosting
- Built-in Egress for recording
- TypeScript SDK with Zod-native tools
- $0.01/min agent hosting

**Consequences:** LiveKit dependency (can self-host later).

---

## ADR-007: Cloudflare R2 for Storage

**Status:** Accepted

**Decision:** Use Cloudflare R2.

**Rationale:**
- Zero egress fees (critical for audio playback)
- S3-compatible API
- Same provider as Workers

**Consequences:** Cloudflare ecosystem dependency.

---

## ADR-008: TypeScript Agent over Python

**Status:** Accepted

**Decision:** Use `@livekit/agents` (Node.js) instead of Python.

**Rationale:**
- Single language across entire stack
- Shared Zod schemas between API and agent
- `@livekit/agents` v1.0.5 is stable (released Aug 2025)
- Same deployment workflow (`lk agent deploy`)
- No Python tooling overhead

**Consequences:** None significant. Node.js SDK has feature parity with Python.

---

## ADR-009: Bun Workspaces without Turborepo

**Status:** Accepted

**Decision:** Use Bun workspaces only.

**Rationale:**
- Bun handles linking natively
- No build caching needed at MVP scale
- Can add Turborepo later if needed

**Consequences:** No remote caching (acceptable for MVP).

---

# Part 4: Appendices

## A.1 Commands

```bash
# Install
bun install

# Development
bun run dev              # web + api concurrently
bun run dev:web          # localhost:3000
bun run dev:api          # localhost:8787
bun run dev:agent        # local agent

# Build
bun run build
bun run build:web
bun run build:api
bun run build:agent

# Test
bun test                 # unit + integration
bun run test:e2e         # Playwright

# Quality
bun run typecheck
bun run lint
bun run fmt

# Database
cd apps/api
bun run db:generate      # generate migration
bun run db:push          # apply to database
bun run db:studio        # open Drizzle Studio

# Agent
cd apps/agent
lk agent dev             # local development
lk agent deploy          # deploy to LiveKit Cloud
```

## A.2 Setup Checklist

### Prerequisites

- [ ] Bun 1.3+ (`curl -fsSL https://bun.sh/install | bash`)
- [ ] Node 20+ (for LiveKit agent CLI)
- [ ] Git

### Accounts

- [ ] Neon — database
- [ ] LiveKit Cloud — WebRTC + agent
- [ ] Cloudflare — R2 bucket + Workers
- [ ] Twilio — SMS
- [ ] OpenAI — GPT-4o API
- [ ] Vercel — frontend hosting

### Local Setup

1. Clone repo
2. `cp .env.example .env.local`
3. Fill all environment variables
4. `bun install`
5. `cd apps/api && bun run db:push`
6. `bun run dev`
7. Open http://localhost:3000

## A.3 Conventions

### Code Style

- TypeScript strict mode, no `any`
- Explicit return types on exports
- `type` over `interface`
- Files: `kebab-case.ts`
- Components: `PascalCase.tsx`

### Imports Order

```typescript
// 1. External
import { Hono } from "hono";
// 2. Workspace
import { CreateInviteRequest } from "@ember/domain";
// 3. Relative
import { db } from "../db/client";
```

### Git Commits

```
feat: add invite creation
fix: handle expired tokens
docs: update API spec
refactor: extract auth middleware
test: add E2E invite flow
chore: update dependencies
```

## A.4 Troubleshooting

| Error | Solution |
|-------|----------|
| `Cannot find @ember/domain` | Run `bun install` from root |
| `DATABASE_URL undefined` | Check `.env.local` exists |
| `LIVEKIT_API_KEY undefined` | Check `.env.local` |
| Agent not connecting | Verify `wss://` prefix, check credentials |
| Playwright failing | Run `bunx playwright install --with-deps` |
| CORS errors | Check API origin whitelist |

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.1.0 | 2025-11-25 | Switch to TypeScript agent, simplify data model, add recording architecture |
| 1.0.0 | 2025-11-25 | Initial specification |

---

*End of Specification*
