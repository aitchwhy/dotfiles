/**
 * FileSystem Effect Layer
 *
 * Provides file system operations as an Effect Layer.
 * This is the Port/Adapter pattern - generators depend on the Port (FileSystem),
 * and we provide the Adapter (FileSystemLive) at runtime.
 */

import { mkdir, readFile as nodeReadFile, writeFile as nodeWriteFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { Context, Effect, Layer } from 'effect';

// =============================================================================
// Types
// =============================================================================

/**
 * FileTree - represents a virtual file system to be written
 * Keys are relative paths, values are file contents
 */
export type FileTree = Record<string, string>;

/**
 * FileSystem service interface (Port)
 */
export interface FileSystemService {
  readonly readFile: (path: string) => Effect.Effect<string, Error>;
  readonly writeFile: (path: string, content: string) => Effect.Effect<void, Error>;
  readonly createDirectory: (path: string) => Effect.Effect<void, Error>;
  readonly writeTree: (tree: FileTree, basePath: string) => Effect.Effect<void, Error>;
}

// =============================================================================
// Context Tag (Port Definition)
// =============================================================================

/**
 * FileSystem Context Tag - the Port that generators depend on
 */
export class FileSystem extends Context.Tag('FileSystem')<FileSystem, FileSystemService>() {}

// =============================================================================
// Live Implementation (Adapter)
// =============================================================================

/**
 * Create the live FileSystem service implementation
 */
const makeFileSystemService = (): FileSystemService => ({
  readFile: (path: string) =>
    Effect.tryPromise({
      try: () => nodeReadFile(path, 'utf-8'),
      catch: (e) => new Error(`Failed to read file ${path}: ${e}`),
    }),

  writeFile: (path: string, content: string) =>
    Effect.tryPromise({
      try: async () => {
        // Ensure parent directory exists
        await mkdir(dirname(path), { recursive: true });
        await nodeWriteFile(path, content, 'utf-8');
      },
      catch: (e) => new Error(`Failed to write file ${path}: ${e}`),
    }),

  createDirectory: (path: string) =>
    Effect.tryPromise({
      try: () => mkdir(path, { recursive: true }),
      catch: (e) => new Error(`Failed to create directory ${path}: ${e}`),
    }).pipe(Effect.asVoid),

  writeTree: (tree: FileTree, basePath: string) =>
    Effect.forEach(
      Object.entries(tree),
      ([relativePath, content]) => {
        const fullPath = join(basePath, relativePath);
        return Effect.tryPromise({
          try: async () => {
            await mkdir(dirname(fullPath), { recursive: true });
            await nodeWriteFile(fullPath, content, 'utf-8');
          },
          catch: (e) => new Error(`Failed to write ${fullPath}: ${e}`),
        });
      },
      { concurrency: 'unbounded' }
    ).pipe(Effect.asVoid),
});

/**
 * FileSystemLive - the live Layer providing the FileSystem service
 */
export const FileSystemLive = Layer.succeed(FileSystem, makeFileSystemService());

// =============================================================================
// Convenience Functions
// =============================================================================

/**
 * Read a file - requires FileSystem in context
 */
export const readFile = (path: string): Effect.Effect<string, Error, FileSystem> =>
  Effect.flatMap(FileSystem, (fs) => fs.readFile(path));

/**
 * Write a file - requires FileSystem in context
 */
export const writeFile = (path: string, content: string): Effect.Effect<void, Error, FileSystem> =>
  Effect.flatMap(FileSystem, (fs) => fs.writeFile(path, content));

/**
 * Create a directory - requires FileSystem in context
 */
export const createDirectory = (path: string): Effect.Effect<void, Error, FileSystem> =>
  Effect.flatMap(FileSystem, (fs) => fs.createDirectory(path));

/**
 * Write a file tree - requires FileSystem in context
 */
export const writeTree = (
  tree: FileTree,
  basePath: string
): Effect.Effect<void, Error, FileSystem> =>
  Effect.flatMap(FileSystem, (fs) => fs.writeTree(tree, basePath));
