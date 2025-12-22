/**
 * Evolution System Domain Errors
 *
 * Using Effect's Data.TaggedError for type-safe error handling.
 */

import { Data } from "effect";

export class CommandError extends Data.TaggedError("CommandError")<{
	readonly command: string;
	readonly args: readonly string[];
	readonly exitCode: number;
	readonly stderr: string;
}> {}

export class DatabaseError extends Data.TaggedError("DatabaseError")<{
	readonly operation: string;
	readonly cause: unknown;
}> {}

export class FileSystemError extends Data.TaggedError("FileSystemError")<{
	readonly path: string;
	readonly operation: "read" | "write" | "stat";
	readonly cause: unknown;
}> {}
