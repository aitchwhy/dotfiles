/**
 * FileSystem Layer Tests
 *
 * Tests for the Effect Layer that handles file system operations.
 */
import { Effect, Exit, Layer } from 'effect'
import { afterEach, beforeEach, describe, expect, test } from 'bun:test'
import { existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import {
  FileSystem,
  FileSystemLive,
  type FileTree,
  createDirectory,
  readFile,
  writeFile,
  writeTree,
} from '@/layers/file-system'

describe('FileSystem Layer', () => {
  let testDir: string

  beforeEach(() => {
    testDir = join(tmpdir(), `factory-test-${Date.now()}`)
    mkdirSync(testDir, { recursive: true })
  })

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true })
  })

  describe('readFile', () => {
    test('reads existing file', async () => {
      const filePath = join(testDir, 'test.txt')
      writeFileSync(filePath, 'hello world')

      const program = readFile(filePath).pipe(Effect.provide(FileSystemLive))
      const result = await Effect.runPromise(program)

      expect(result).toBe('hello world')
    })

    test('fails for non-existent file', async () => {
      const filePath = join(testDir, 'missing.txt')

      const program = readFile(filePath).pipe(Effect.provide(FileSystemLive))
      const exit = await Effect.runPromiseExit(program)

      expect(Exit.isFailure(exit)).toBe(true)
    })
  })

  describe('writeFile', () => {
    test('writes new file', async () => {
      const filePath = join(testDir, 'output.txt')

      const program = writeFile(filePath, 'test content').pipe(Effect.provide(FileSystemLive))
      await Effect.runPromise(program)

      expect(existsSync(filePath)).toBe(true)
      const content = Bun.file(filePath).text()
      expect(await content).toBe('test content')
    })

    test('creates parent directories', async () => {
      const filePath = join(testDir, 'nested', 'deep', 'file.txt')

      const program = writeFile(filePath, 'nested content').pipe(Effect.provide(FileSystemLive))
      await Effect.runPromise(program)

      expect(existsSync(filePath)).toBe(true)
    })

    test('overwrites existing file', async () => {
      const filePath = join(testDir, 'existing.txt')
      writeFileSync(filePath, 'old content')

      const program = writeFile(filePath, 'new content').pipe(Effect.provide(FileSystemLive))
      await Effect.runPromise(program)

      const content = await Bun.file(filePath).text()
      expect(content).toBe('new content')
    })
  })

  describe('createDirectory', () => {
    test('creates new directory', async () => {
      const dirPath = join(testDir, 'new-dir')

      const program = createDirectory(dirPath).pipe(Effect.provide(FileSystemLive))
      await Effect.runPromise(program)

      expect(existsSync(dirPath)).toBe(true)
    })

    test('creates nested directories', async () => {
      const dirPath = join(testDir, 'a', 'b', 'c')

      const program = createDirectory(dirPath).pipe(Effect.provide(FileSystemLive))
      await Effect.runPromise(program)

      expect(existsSync(dirPath)).toBe(true)
    })

    test('succeeds for existing directory', async () => {
      const dirPath = join(testDir, 'existing-dir')
      mkdirSync(dirPath)

      const program = createDirectory(dirPath).pipe(Effect.provide(FileSystemLive))
      await Effect.runPromise(program)

      expect(existsSync(dirPath)).toBe(true)
    })
  })

  describe('writeTree', () => {
    test('writes flat file tree', async () => {
      const tree: FileTree = {
        'file1.txt': 'content 1',
        'file2.txt': 'content 2',
      }

      const program = writeTree(tree, testDir).pipe(Effect.provide(FileSystemLive))
      await Effect.runPromise(program)

      expect(await Bun.file(join(testDir, 'file1.txt')).text()).toBe('content 1')
      expect(await Bun.file(join(testDir, 'file2.txt')).text()).toBe('content 2')
    })

    test('writes nested file tree', async () => {
      const tree: FileTree = {
        'root.txt': 'root content',
        'src/index.ts': 'export {}',
        'src/lib/utils.ts': 'export const utils = {}',
      }

      const program = writeTree(tree, testDir).pipe(Effect.provide(FileSystemLive))
      await Effect.runPromise(program)

      expect(await Bun.file(join(testDir, 'root.txt')).text()).toBe('root content')
      expect(await Bun.file(join(testDir, 'src/index.ts')).text()).toBe('export {}')
      expect(await Bun.file(join(testDir, 'src/lib/utils.ts')).text()).toBe(
        'export const utils = {}'
      )
    })

    test('handles empty tree', async () => {
      const tree: FileTree = {}

      const program = writeTree(tree, testDir).pipe(Effect.provide(FileSystemLive))
      await Effect.runPromise(program)

      // Should not throw
      expect(true).toBe(true)
    })
  })
})
