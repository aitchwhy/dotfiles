# Platform Code-Generation Overview

> **TL;DR**  `schemas → codegen → gen → lib → app`.
>
> *Schemas are the specs* → *Codegen turns them into language-specific artefacts* → *Generated artefacts live in `gen/`* → *Hand-written helper libraries in `lib/` wrap those artefacts* → Everything above is consumed by services, gateways, workflows, and front-ends.

---

## 1  `schemas/` – Single Source of Truth

| Sub-dir | Kind of schema | Typical toolchain |
|---------|----------------|-------------------|
| `proto/` | Protobuf service & message definitions | **Buf** → Go/Python/TS gRPC stubs |
| `openapi/` | REST/OpenAPI specifications | **openapi-generator** → typed clients |
| `events/` | Event envelopes (e.g. Kafka, SNS) | Registry docs / Avro / JSON-Schema |
| `data/` | Raw data models (JSON-Schema) | Code-model generators |
| `workflows/` | Workflow DSL / state machines | Prefect, Temporal, etc. |

*Never* import from here at runtime – these files are language-agnostic specifications only.

## 2  `codegen/` – All Generators & Templates

The `codegen/` directory contains containerised scripts (usually run via `ant codegen`) that read from `schemas/` and write to `gen/`.

Key folders:

* **`codegen/proto/`** – Runs Buf to emit Go & Python protobuf stubs.
* **`codegen/models/`** – Converts JSON-Schema → Go structs / Pydantic / Zod.
* **`codegen/openapi-client/`** – Generates REST API clients for multiple languages.
* **`codegen/compose/`** – Stamps out many environment-specific Docker Compose files.

These scripts are *build-time only*; nothing inside `codegen/` is imported by application code.

## 3  `gen/` – Generated Artefacts (Checked-in)

`gen/` is the mounted output directory for all generators.  Layout:

```
 gen/
   ├─ go/       # Go structs, clients, mocks …
   ├─ python/   # Pydantic & FastAPI models …
   ├─ ts/       # Zod schemas, TypeScript types …
   ├─ compose/  # Pre-baked docker-compose YAMLs
   └─ docs/     # Reference documentation
```

Rules:

1. Never hand-edit files in `gen/`.
2. Always commit the diff so CI/CD & IDEs don't require local regeneration.

## 4  `lib/{go,ts,python}/` – Hand-Written Shared Libraries

These packages sit *on top* of the raw generated code, providing ergonomics, helpers and business logic.  Examples:

* `lib/ts/lib-platform/…` – HTTP app framework, structured logging helpers, Zod utilities.
* `lib/go/prefect/…` – Convenience wrappers around Prefect-generated types.
* `lib/python/src/lib/…` – Cross-service Python utilities.

Application layers import from **both** `gen/` and `lib/`.

## 5  `compose/` vs `codegen/compose/`

* `codegen/compose/` – Templates + generation logic.
* `compose/` – The frozen YAMLs produced by that logic.

Same pattern: template → generated output.

## 6  Developer Workflow

```text
1. Edit a schema   (schemas/…)
2. Run codegen      ant codegen
3. Commit schema change + generated diff (gen/…)
4. Extend helpers   (lib/…) if needed
5. Use new types    in services, gateways, etc.
```

Keep this pipeline in mind whenever you wonder, "Where does this type/client come from?" – start at `schemas/` and follow the arrows downstream.