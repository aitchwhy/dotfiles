/**
 * AST-grep config discovery — Node-only (no `bun` imports) so tests can
 * run under vitest's Node pool.
 *
 * Returns the nearest ancestor directory containing one or more
 * `sgconfig*.yml` files, plus every matching config basename.
 *
 * Repos like ~/src/told carry both `sgconfig.yml` (app rules) and
 * `sgconfig-infra.yml` (infra rules); both must be scanned on every edit.
 */
import * as fs from 'node:fs'
import * as path from 'node:path'

export interface SgConfigDiscovery {
  readonly root: string
  readonly configs: readonly string[]
}

export const findSgConfigs = (file: string): SgConfigDiscovery | null => {
  let dir = path.dirname(file)
  while (dir !== '/' && dir !== '.') {
    const configs = listSgConfigsAt(dir)
    if (configs.length > 0) return { root: dir, configs }
    dir = path.dirname(dir)
  }
  return null
}

const listSgConfigsAt = (dir: string): string[] => {
  try {
    return fs
      .readdirSync(dir)
      .filter((name) => /^sgconfig.*\.yml$/.test(name))
      .sort()
  } catch {
    return []
  }
}
