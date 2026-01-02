/**
 * CI System Domain Errors
 *
 * Using Effect's Data.TaggedError for type-safe error handling.
 */

import { Data } from 'effect'

export class GuardFailure extends Data.TaggedError('GuardFailure')<{
  readonly guard: string
  readonly matches: readonly string[]
}> {}

export class CommandError extends Data.TaggedError('CommandError')<{
  readonly command: string
  readonly args: readonly string[]
  readonly exitCode: number
  readonly stderr: string
}> {}

export class CIStepFailure extends Data.TaggedError('CIStepFailure')<{
  readonly step: string
  readonly reason: string
}> {}
