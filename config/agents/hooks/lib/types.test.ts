/**
 * Tests for PARAGON hook types with Effect Schema
 */

import { describe, it, expect } from "vitest";
import { Effect, Either } from "effect";

// These imports will fail until we implement the types
import {
  decodePreToolUseInput,
  decodeStopInput,
  decodeGenericHookInput,
  isExcludedPath,
  isTypeScriptFile,
  isNixFile,
  type PreToolUseInput,
  type StopInput,
} from "./types";

describe("Effect Schema Decoders", () => {
  describe("decodePreToolUseInput", () => {
    it("decodes valid PreToolUse input", async () => {
      const input = {
        hook_event_name: "PreToolUse",
        session_id: "test-session",
        tool_name: "Write",
        tool_input: {
          file_path: "/path/to/file.ts",
          content: "const x = 1;",
        },
      };

      const result = await Effect.runPromise(
        Effect.either(decodePreToolUseInput(input))
      );

      expect(Either.isRight(result)).toBe(true);
      if (Either.isRight(result)) {
        expect(result.right.hook_event_name).toBe("PreToolUse");
        expect(result.right.tool_name).toBe("Write");
        expect(result.right.tool_input.file_path).toBe("/path/to/file.ts");
      }
    });

    it("returns Left for invalid hook_event_name", async () => {
      const input = {
        hook_event_name: "PostToolUse", // Wrong literal
        session_id: "test-session",
        tool_name: "Write",
        tool_input: {},
      };

      const result = await Effect.runPromise(
        Effect.either(decodePreToolUseInput(input))
      );

      expect(Either.isLeft(result)).toBe(true);
    });

    it("returns Left for missing required fields", async () => {
      const input = {
        hook_event_name: "PreToolUse",
        // Missing session_id and tool_name
      };

      const result = await Effect.runPromise(
        Effect.either(decodePreToolUseInput(input))
      );

      expect(Either.isLeft(result)).toBe(true);
    });

    it("allows extra fields in tool_input via Record extension", async () => {
      const input = {
        hook_event_name: "PreToolUse",
        session_id: "test-session",
        tool_name: "Bash",
        tool_input: {
          command: "ls -la",
          custom_field: "should be allowed",
        },
      };

      const result = await Effect.runPromise(
        Effect.either(decodePreToolUseInput(input))
      );

      expect(Either.isRight(result)).toBe(true);
    });
  });

  describe("decodeStopInput", () => {
    it("decodes valid Stop input", async () => {
      const input = {
        hook_event_name: "Stop",
        session_id: "test-session",
        cwd: "/path/to/project",
      };

      const result = await Effect.runPromise(
        Effect.either(decodeStopInput(input))
      );

      expect(Either.isRight(result)).toBe(true);
      if (Either.isRight(result)) {
        expect(result.right.hook_event_name).toBe("Stop");
        expect(result.right.cwd).toBe("/path/to/project");
      }
    });

    it("allows optional cwd", async () => {
      const input = {
        hook_event_name: "Stop",
        session_id: "test-session",
      };

      const result = await Effect.runPromise(
        Effect.either(decodeStopInput(input))
      );

      expect(Either.isRight(result)).toBe(true);
    });
  });

  describe("decodeGenericHookInput", () => {
    it("decodes any hook event name", async () => {
      const input = {
        hook_event_name: "AnyEvent",
        session_id: "test-session",
      };

      const result = await Effect.runPromise(
        Effect.either(decodeGenericHookInput(input))
      );

      expect(Either.isRight(result)).toBe(true);
    });
  });
});

describe("File Pattern Utilities", () => {
  describe("isExcludedPath", () => {
    it("excludes test files", () => {
      expect(isExcludedPath("src/utils.test.ts")).toBe(true);
      expect(isExcludedPath("src/utils.spec.tsx")).toBe(true);
    });

    it("excludes .d.ts files", () => {
      expect(isExcludedPath("types/index.d.ts")).toBe(true);
    });

    it("excludes API boundary files", () => {
      expect(isExcludedPath("/api/users.ts")).toBe(true);
    });

    it("excludes node_modules", () => {
      expect(isExcludedPath("/node_modules/effect/index.js")).toBe(true);
    });

    it("excludes schema files", () => {
      expect(isExcludedPath("user.schema.ts")).toBe(true);
      expect(isExcludedPath("/schemas/user.ts")).toBe(true);
    });

    it("excludes guard files", () => {
      expect(isExcludedPath("paragon-guard.ts")).toBe(true);
    });

    it("does not exclude regular source files", () => {
      expect(isExcludedPath("src/utils.ts")).toBe(false);
      expect(isExcludedPath("lib/helper.tsx")).toBe(false);
    });
  });

  describe("isTypeScriptFile", () => {
    it("matches .ts files", () => {
      expect(isTypeScriptFile("src/index.ts")).toBe(true);
    });

    it("matches .tsx files", () => {
      expect(isTypeScriptFile("components/Button.tsx")).toBe(true);
    });

    it("matches .js and .jsx files", () => {
      expect(isTypeScriptFile("src/legacy.js")).toBe(true);
      expect(isTypeScriptFile("components/Old.jsx")).toBe(true);
    });

    it("excludes .d.ts files", () => {
      expect(isTypeScriptFile("types/index.d.ts")).toBe(false);
    });

    it("excludes non-TypeScript files", () => {
      expect(isTypeScriptFile("README.md")).toBe(false);
      expect(isTypeScriptFile("styles.css")).toBe(false);
    });
  });

  describe("isNixFile", () => {
    it("matches .nix files", () => {
      expect(isNixFile("flake.nix")).toBe(true);
      expect(isNixFile("modules/home.nix")).toBe(true);
    });

    it("excludes non-Nix files", () => {
      expect(isNixFile("index.ts")).toBe(false);
      expect(isNixFile("config.json")).toBe(false);
    });
  });
});
