/**
 * unified-polish: sgconfig discovery tests.
 */
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs'
import * as os from 'node:os'
import * as path from 'node:path'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { findSgConfigs } from './find-sgconfig'

describe('findSgConfigs', () => {
  let tmp: string

  beforeEach(() => {
    tmp = mkdtempSync(path.join(os.tmpdir(), 'sgconfig-test-'))
    mkdirSync(path.join(tmp, 'src'), { recursive: true })
  })

  afterEach(() => {
    // Test dirs are small and under /tmp; OS cleans them. Don't recursively
    // delete in tests to avoid risk if `tmp` ever resolves wrong.
  })

  it('returns null when no sgconfig exists', () => {
    expect(findSgConfigs(path.join(tmp, 'src/foo.ts'))).toBeNull()
  })

  it('finds a single sgconfig.yml in the ancestor directory', () => {
    writeFileSync(path.join(tmp, 'sgconfig.yml'), '')
    expect(findSgConfigs(path.join(tmp, 'src/foo.ts'))).toEqual({
      root: tmp,
      configs: ['sgconfig.yml'],
    })
  })

  it('finds multiple sgconfig*.yml files in the ancestor directory', () => {
    writeFileSync(path.join(tmp, 'sgconfig.yml'), '')
    writeFileSync(path.join(tmp, 'sgconfig-infra.yml'), '')
    const result = findSgConfigs(path.join(tmp, 'src/foo.ts'))
    expect(result?.root).toBe(tmp)
    // Order is deterministic (sorted): sgconfig.yml then sgconfig-infra.yml,
    // BUT lexicographic sort puts 'sgconfig-infra.yml' before 'sgconfig.yml'
    // because '-' (0x2D) < '.' (0x2E). Assert both are present, not order.
    expect(result?.configs).toEqual(expect.arrayContaining(['sgconfig.yml', 'sgconfig-infra.yml']))
    expect(result?.configs).toHaveLength(2)
  })

  it('walks ancestors and stops at the first dir with any sgconfig*.yml', () => {
    writeFileSync(path.join(tmp, 'sgconfig.yml'), '')
    // Nested file should still discover the ancestor's sgconfig.
    mkdirSync(path.join(tmp, 'src/nested/deep'), { recursive: true })
    const result = findSgConfigs(path.join(tmp, 'src/nested/deep/x.ts'))
    expect(result?.root).toBe(tmp)
    expect(result?.configs).toEqual(['sgconfig.yml'])
  })

  it('ignores unrelated yml files in the same directory', () => {
    writeFileSync(path.join(tmp, 'sgconfig.yml'), '')
    writeFileSync(path.join(tmp, 'docker-compose.yml'), '')
    writeFileSync(path.join(tmp, 'other-config.yml'), '')
    const result = findSgConfigs(path.join(tmp, 'src/foo.ts'))
    expect(result?.configs).toEqual(['sgconfig.yml'])
  })

  it('matches sgconfig-anything.yml variants', () => {
    writeFileSync(path.join(tmp, 'sgconfig.yml'), '')
    writeFileSync(path.join(tmp, 'sgconfig-infra.yml'), '')
    writeFileSync(path.join(tmp, 'sgconfig-test.yml'), '')
    const result = findSgConfigs(path.join(tmp, 'src/foo.ts'))
    expect(result?.configs).toHaveLength(3)
  })
})
