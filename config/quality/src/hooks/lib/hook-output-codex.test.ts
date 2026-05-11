/**
 * Codex hook output adapter tests.
 */
import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { isCodexOutputContext, shouldSuppressDecision } from './hook-output-codex'

const ENV_KEY = 'CODEX_HOME'
let prev: string | undefined

beforeEach(() => {
  prev = process.env[ENV_KEY]
})

afterEach(() => {
  if (prev === undefined) {
    delete process.env[ENV_KEY]
  } else {
    process.env[ENV_KEY] = prev
  }
})

describe('isCodexOutputContext', () => {
  it('returns true when CODEX_HOME is a non-empty string', () => {
    process.env[ENV_KEY] = '/Users/hank/.codex-max-1'
    expect(isCodexOutputContext()).toBe(true)
  })

  it('returns false when CODEX_HOME is unset', () => {
    delete process.env[ENV_KEY]
    expect(isCodexOutputContext()).toBe(false)
  })

  it('returns false when CODEX_HOME is an empty string', () => {
    process.env[ENV_KEY] = ''
    expect(isCodexOutputContext()).toBe(false)
  })
})

describe('shouldSuppressDecision — under Codex', () => {
  beforeEach(() => {
    process.env[ENV_KEY] = '/Users/hank/.codex-max-1'
  })

  it('suppresses approve', () => {
    expect(shouldSuppressDecision({ decision: 'approve' })).toBe(true)
  })

  it('suppresses approve with reason', () => {
    expect(shouldSuppressDecision({ decision: 'approve', reason: 'guard passed' })).toBe(true)
  })

  it('suppresses skip', () => {
    expect(shouldSuppressDecision({ decision: 'skip' })).toBe(true)
  })

  it('emits block (never suppressed)', () => {
    expect(shouldSuppressDecision({ decision: 'block', reason: 'forbidden file' })).toBe(false)
  })
})

describe('shouldSuppressDecision — under Claude Code', () => {
  beforeEach(() => {
    delete process.env[ENV_KEY]
  })

  it('emits approve (no suppression without CODEX_HOME)', () => {
    expect(shouldSuppressDecision({ decision: 'approve' })).toBe(false)
  })

  it('emits skip (no suppression without CODEX_HOME)', () => {
    expect(shouldSuppressDecision({ decision: 'skip' })).toBe(false)
  })

  it('emits block (no suppression without CODEX_HOME)', () => {
    expect(shouldSuppressDecision({ decision: 'block', reason: 'x' })).toBe(false)
  })
})
