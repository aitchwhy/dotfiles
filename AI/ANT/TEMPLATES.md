# End-to-End MNR Workflow (PDF-handling)

This document explains, from request to result, how the **Medical Necessity Review** (MNR) workflow is implemented across the TypeScript *Gateway* and the Python *Workers* that run on brrr.

> **Scope**
> • TypeScript side: `app.ts`, `schemas.ts`, `utils/artifacts/index.ts`, `handlers/run-mnr-raw.ts`
> • Python side: `workflows/src/generic/tasks/*.py` (notably `mnr.py`, `convert_artifact.py`, etc.)
> • Orchestration: `TaskScheduler` ➜ SQS ➜ *prefect-agent* ➜ **brrr**

---

## 1. Public HTTP Surface (TypeScript)

### 1.1 Route definition
```130:170:platform/gateways/noggin/src/tasks/app.ts
app.endpoint({
  method: "POST",
  route: "/mnr/actions/run",
  body: z.object({
    stemId: z.string().optional(),
    artQueries: z.object({
      member: antQuerySchema.optional(),
      criteria: antQuerySchema,
      clinicals: z.array(antQuerySchema),
    }),
    serviceRequest: attachServicesToStemV11.shape.services.element,
  }),
  handler: async (ctx) => { /* … */ }
});
```

* **Validation** – Zod schemas ensure client input is well-formed.
* **Auth** – `parseAuthInfo(ctx)` extracts JWT claims (enterprise / workspace / user IDs).

### 1.2 Handler logic (excerpt)
```90:130:platform/gateways/noggin/src/tasks/app.ts
const originalClincials: string[] = [];
for (const c of clinicals) {
  const original = await getArtifactsFor(c, workspaceUid, ".orig");
  originalClincials.push(...original);
}
const gdt = (await getArtifactsFor(criteria, workspaceUid, ".gdt"))[0];
```
*Uses `utils/artifacts/index.ts` helpers to convert `ant://` URIs into real S3 keys and fetch specific versions of artifacts (PDF originals, GDT JSON, …).*
If all artifacts resolve ➜ call **`runMnrRaw`**.

---

## 2. Task Construction & Scheduling (TypeScript)

### 2.1 Runtime schema
```1:40:platform/gateways/noggin/src/tasks/schemas.ts
export const mnr_task = z.object({
  config: z.object({ /* workflo_meta, source_meta, workspace_config */ }),
  member_query: z.string().nullable(),
  service: service_request,
  clinicals_query: z.array(z.string()),
  gdt_query: z.string(),
});
export type MNRTask = Readonly<z.infer<typeof mnr_task>>;
```

### 2.2 Building the payload
```20:70:platform/gateways/noggin/src/tasks/handlers/run-mnr-raw.ts
await platform.mnrTasks.schedule({
  task_name: "execute_and_determine_mnr",
  config: {/* meta incl. trace_id */},
  member_query: artQueries.member ?? null,
  service: { /* simplified FHIR ServiceRequest */ },
  clinicals_query: artQueries.clinicals,
  gdt_query: artQueries.criteria,
});
```

### 2.3 TaskScheduler mechanics
```1:29:platform/lib/ts/lib-platform/src/tasks.ts
await this.queue.send(serialized); // serialized is {workflow_name, parameters}
```
`infra.taskQueue` is SQS in production; in-memory in tests.

---

## 3. Bridging to brrr (Python)

1. **prefect-agent** (`services/prefect-agent`) continuously *receives* SQS messages.
2. If `payload.workflow_engine == "brrr"` it calls
   ```py
   await brrr.schedule(payload.workflow_name, (), payload.parameters)
   ```
   but MNR still runs through **Prefect** → **brrr proxy** for now; the agent eventually issues the same `brrr.schedule` after Prefect flow routing.

3. Message is encoded with `AnteriorCodec` (tracing, error envelope) and placed on Redis stream that **brrr** workers listen to.

---

## 4. Worker-Side Execution (Python brrr tasks)

### 4.1 Entry task
```1:30:platform/workflows/src/generic/tasks/mnr.py
@brrr.task
async def execute_and_determine_mnr(
  config: Config,
  member_query: Query[Patient] | None,
  service: ServiceRequest,
  clinicals_query: list[ClinicalQuery],
  gdt_query: Query[GDT],
) -> Query[MNRDetermination]:
  execution_query = await execute_mnr(config, service, clinicals_query, gdt_query)
  return await create_determination(config, member_query, service, execution_query)
```

### 4.2 PDF pipeline
1. `convert_artifact` – If clinical source isn't already a PDF it calls **Gotenberg** to produce one, caches result in artifact store.
2. `extract_clinical` – Runs either *Reducto* or *Google Cloud Vision* to pull structured data; result saved as `extraction.json`.
3. `execute_mnr_kernel` – Domain logic combines FHIR ServiceRequest, ClinicalExtraction(s), and GDT to get an `Execution` tree.
4. `create_determination` – Uses LLM prompt templates to turn execution into a human-readable summary, stores `MNRDetermination` JSON.

### 4.3 Event emission
Workers use `config.save_event(StemLogV11(…))` to write to the stem-event bus (Datadog & UI streaming).

---

## 5. Artifact Path Convention (shared)
*See `utils/artifacts/index.ts` for helpers.*
```
artifacts/{workspaceUid}/{category}/{sourceId}/{artifactId}.{ext}
```
• PDFs live under `clinicals/<stemId>/<uuid>.raw.pdf`
• GDT under `criteria/<gdtId>/<gdtId>.gdt.json`
Helpers like `getArtifactsFor()` fetch variants by suffix (`.orig`, `.gdt`, …).

---

## 6. Contract between TS & Python

| Layer | Key                         | Value                                                     |
|-------|-----------------------------|-----------------------------------------------------------|
| TS → Py | `workflow_name`            | `execute_and_determine_mnr`                               |
| TS → Py | `parameters`              | Matches **`MNRTask`** Zod schema                          |
| Py side | Input parameters          | Pydantic-validated via `Config`, `Query[T]`, FHIR models  |
| Py → TS | Events / Artifacts        | `StemLogV11`, `MNRDetermination` stored & evented         |

Both languages rely on the **`ant://` URI** convention so neither side needs direct S3 credentials.

---

## 7. Flow Summary
1. **Client** POSTs to `/mnr/actions/run` with Ant URIs.
2. **Gateway** validates, resolves PDF originals & GDT, enqueues task.
3. **prefect-agent** forwards to **brrr**.
4. **Worker** converts / extracts PDFs, runs kernel, summarises.
5. **Artifacts & Events** surface back; UI subscribes to stem-events for progress & outcome.
