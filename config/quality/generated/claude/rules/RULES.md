# Quality Rules

Total: 20 rules

## type-safety

| Rule | Severity | Patterns | Fix |
|------|----------|----------|-----|
| no-any | error | : any, as any, <any> | Use 'unknown' and narrow with type guards, or define proper types |
| no-zod | error | from "zod", z.object, z.infer, z.string | Use Effect Schema with TypeScript types as SSOT: Schema satisfies Schema.Schema<Type> |
| require-branded-id | warning | userId: string, orderId: string, id: string | Use branded types: type UserId = string & Brand.Brand<'UserId'> |

## effect

| Rule | Severity | Patterns | Fix |
|------|----------|----------|-----|
| no-try-catch | error | try {, } catch | Use Effect.tryPromise or Effect.try for external code, Effect.gen for internal |
| require-effect-gen | warning | Effect.flatMap, Effect.andThen | Use Effect.gen(function* () { const x = yield* effect; }) for clarity |
| require-tagged-error | error | new Error(", Effect.fail(new Error | Use Data.TaggedError: class MyError extends Data.TaggedError('MyError')<{...}>() {} |
| no-throw | error | throw new, throw  | Return Effect.fail(error) or use Result types |
| no-process-env | error | process.env., Bun.env. | Use a Config service: yield* Config; with ConfigLive/ConfigTest layers |
| no-raw-promise | error | new Promise, Promise.resolve, Promise.reject | Use Effect.promise, Effect.tryPromise, or Effect.async |
| no-async-function | warning | async function, async () =>, async () | Use Effect.gen(function*() { ... }) |
| no-await | error | await  | yield* effect |

## effect-xstate

| Rule | Severity | Patterns | Fix |
|------|----------|----------|-----|
| no-runpromise-then-catch | error | Effect.runPromise(, .then(, .catch( | Use Effect.runPromiseExit() + Exit.isFailure()/isSuccess() |
| no-ref-for-machine-state | warning | useRef<, useMachine(, useActor( | Store API responses, tokens, URLs in machine context via assign() |
| no-useeffect-runpromise | error | useEffect(, Effect.runPromise( | Use XState invoke with fromPromise actor instead |
| no-string-error-conversion | warning | String(err), .message | Preserve Effect Cause types or use Schema.TaggedError |

## architecture

| Rule | Severity | Patterns | Fix |
|------|----------|----------|-----|
| no-mock | error | jest.mock(, vi.mock(, jest.fn(, vi.fn( | Use Layer substitution: Effect.provide(TestLayer) with real implementations |
| port-requires-adapter | warning | extends Context.Tag( | Create Live and Test layers: Layer.succeed(Port, { ...impl }) |
| no-forbidden-import | error | from "lodash", from "express", from "axios", from "moment", from "prisma", from "hono" | Use stack alternatives: Effect for FP, @effect/platform for HTTP, Temporal for dates, Drizzle for DB |
| no-env-conditionals | error | NODE_ENV, ENVIRONMENT, IS_PROD, IS_DEV, IS_PRODUCTION, IS_DEVELOPMENT, IS_TEST, import.meta.env.MODE, import.meta.env.DEV, import.meta.env.PROD, === "production", === "development", === "test", === 'production', === 'development', === 'test' | Inject behavior flags via Config service: { showStackTraces: false, logLevel: "warn" } loaded from config file or CLI args |

## observability

| Rule | Severity | Patterns | Fix |
|------|----------|----------|-----|
| no-console | error | console.log(, console.error(, console.warn( | Use Effect.log, Effect.logError, or Effect.logWarning for structured output |
