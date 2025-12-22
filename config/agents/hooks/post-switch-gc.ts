#!/usr/bin/env bun
/**
 * Post-Switch GC Hook
 *
 * Runs after darwin-rebuild switch. Spawns background Nix garbage collection.
 * Non-blocking - returns immediately after spawning.
 */

import { Effect, pipe } from "effect";

// =============================================================================
// Main
// =============================================================================

const program = Effect.sync(() => {
	// Run nix-collect-garbage in background (fire and forget)
	Bun.spawn(["nix-collect-garbage", "-d"], {
		stdout: "ignore",
		stderr: "ignore",
	});

	// Log that we started (to stderr, not stdout protocol)
	process.stderr.write(JSON.stringify({
		level: "info",
		context: "post-switch-gc",
		message: "Started background Nix garbage collection",
		timestamp: new Date().toISOString(),
	}) + "\n");

	// Return success immediately
	process.stdout.write(JSON.stringify({ continue: true }) + "\n");
});

// =============================================================================
// Run
// =============================================================================

pipe(
	program,
	Effect.catchAll((error) => {
		// Log error but don't block
		process.stderr.write(JSON.stringify({
			level: "error",
			context: "post-switch-gc",
			message: String(error),
			timestamp: new Date().toISOString(),
		}) + "\n");
		process.stdout.write(JSON.stringify({ continue: true }) + "\n");
		return Effect.void;
	}),
	Effect.runPromise,
);
