/**
 * Pattern Engine Effect Layer (ast-grep Implementation)
 *
 * Provides structural pattern matching for TypeScript/JavaScript via ast-grep.
 * Supports YAML rule files for declarative pattern enforcement.
 *
 * This is the Port/Adapter pattern:
 * - Port: PatternService interface (PatternEngine Context.Tag)
 * - Adapter: PatternEngineLive implementation using @ast-grep/napi
 *
 * @see https://ast-grep.github.io/guide/api-usage/js-api.html
 * @version @ast-grep/napi@0.33.1
 */

import { readdir, readFile } from 'node:fs/promises';
import { extname, join } from 'node:path';
import { Lang, parse, type SgNode, type SgRoot } from '@ast-grep/napi';
import { Context, Effect, Layer } from 'effect';
import { parse as parseYaml } from 'yaml';

// =============================================================================
// Types
// =============================================================================

/**
 * Supported languages for pattern matching
 */
export type PatternLanguage = 'TypeScript' | 'JavaScript' | 'Tsx' | 'Jsx' | 'Html' | 'Css';

/**
 * Range in source code
 */
export interface SourceRange {
  readonly start: { readonly line: number; readonly column: number; readonly index: number };
  readonly end: { readonly line: number; readonly column: number; readonly index: number };
}

/**
 * Pattern match result
 */
export interface PatternMatch {
  readonly rule: string;
  readonly severity: RuleSeverity;
  readonly message: string;
  readonly node: {
    readonly text: string;
    readonly range: SourceRange;
    readonly kind: string;
  };
  readonly captures: Record<string, string>;
  readonly fix?: PatternFix;
}

/**
 * Fix suggestion from pattern rule
 */
export interface PatternFix {
  readonly replacement: string;
  readonly description: string;
}

/**
 * Severity levels for rules
 */
export type RuleSeverity = 'error' | 'warning' | 'hint' | 'off';

/**
 * YAML rule configuration (mirrors ast-grep format)
 */
export interface PatternRule {
  readonly id: string;
  readonly language: PatternLanguage;
  readonly severity: RuleSeverity;
  readonly message: string;
  readonly rule: RuleConfig;
  readonly fix?: string;
  readonly note?: string;
  readonly constraints?: Record<string, ConstraintConfig>;
}

/**
 * Rule configuration (ast-grep rule format)
 * @see https://ast-grep.github.io/reference/rule.html
 */
export interface RuleConfig {
  readonly pattern?: string;
  readonly kind?: string;
  readonly regex?: string;
  readonly inside?: RelationalRule;
  readonly has?: RelationalRule;
  readonly precedes?: RelationalRule;
  readonly follows?: RelationalRule;
  readonly all?: readonly RuleConfig[];
  readonly any?: readonly RuleConfig[];
  readonly not?: RuleConfig;
  readonly matches?: string;
}

/**
 * Relational rule for structural queries
 */
export interface RelationalRule extends RuleConfig {
  readonly stopBy?: 'neighbor' | 'end' | RuleConfig;
  readonly field?: string;
}

/**
 * Constraint configuration for metavariables
 */
export interface ConstraintConfig {
  readonly regex?: string;
  readonly kind?: string;
  readonly not?: ConstraintConfig;
}

/**
 * Result of applying rules to a file
 */
export interface RuleApplicationResult {
  readonly filePath: string;
  readonly matches: readonly PatternMatch[];
  readonly hasErrors: boolean;
  readonly hasWarnings: boolean;
}

/**
 * Pattern service interface (Port)
 */
export interface PatternService {
  /** Parse source code into an ast-grep root */
  readonly parseSource: (
    content: string,
    language: PatternLanguage
  ) => Effect.Effect<SgRoot, Error>;

  /** Find all nodes matching a pattern */
  readonly findPattern: (root: SgRoot, pattern: string) => Effect.Effect<readonly SgNode[], Error>;

  /** Apply a single rule to a parsed root */
  readonly applyRule: (
    root: SgRoot,
    rule: PatternRule,
    filePath?: string
  ) => Effect.Effect<readonly PatternMatch[], Error>;

  /** Apply multiple rules to source content */
  readonly applyRules: (
    content: string,
    language: PatternLanguage,
    rules: readonly PatternRule[],
    filePath?: string
  ) => Effect.Effect<RuleApplicationResult, Error>;

  /** Load rules from a YAML file */
  readonly loadRuleFromYaml: (path: string) => Effect.Effect<PatternRule, Error>;

  /** Load all rules from a directory */
  readonly loadRulesFromDirectory: (
    dirPath: string
  ) => Effect.Effect<readonly PatternRule[], Error>;

  /** Apply a fix to content, returning the modified content */
  readonly applyFix: (content: string, match: PatternMatch) => Effect.Effect<string, Error>;

  /** Apply all fixes for a set of matches */
  readonly applyAllFixes: (
    content: string,
    matches: readonly PatternMatch[]
  ) => Effect.Effect<string, Error>;
}

// =============================================================================
// Context Tag (Port Definition)
// =============================================================================

/**
 * PatternEngine Context Tag - the Port that consumers depend on
 */
export class PatternEngine extends Context.Tag('PatternEngine')<PatternEngine, PatternService>() {}

// =============================================================================
// Helper Functions
// =============================================================================

/**
 * Map PatternLanguage to ast-grep Lang enum
 */
const mapLanguage = (language: PatternLanguage): Lang => {
  const langMap: Record<PatternLanguage, Lang> = {
    TypeScript: Lang.TypeScript,
    JavaScript: Lang.JavaScript,
    Tsx: Lang.Tsx,
    Jsx: Lang.JavaScript, // JSX uses JavaScript parser
    Html: Lang.Html,
    Css: Lang.Css,
  };
  return langMap[language];
};

/**
 * Detect language from file extension
 */
export const detectLanguage = (filePath: string): PatternLanguage => {
  const ext = extname(filePath).toLowerCase();
  const langMap: Record<string, PatternLanguage> = {
    '.ts': 'TypeScript',
    '.tsx': 'Tsx',
    '.js': 'JavaScript',
    '.jsx': 'Jsx',
    '.mjs': 'JavaScript',
    '.cjs': 'JavaScript',
    '.html': 'Html',
    '.css': 'Css',
  };
  return langMap[ext] ?? 'TypeScript';
};

/**
 * Extract captures from a matched node
 */
const extractCaptures = (node: SgNode): Record<string, string> => {
  const captures: Record<string, string> = {};

  // Common metavariable patterns
  const commonVars = [
    'METHOD',
    'NAME',
    'PATH',
    'HANDLER',
    'ARGS',
    'MSG',
    'ERROR',
    'APP',
    'CONFIG',
    'ARG',
    'CTX',
    'BODY',
  ];
  for (const varName of commonVars) {
    const match = node.getMatch(varName);
    if (match) {
      captures[varName] = match.text();
    }
  }

  return captures;
};

/**
 * Convert SgNode range to our SourceRange type
 */
const toSourceRange = (node: SgNode): SourceRange => {
  const range = node.range();
  return {
    start: {
      line: range.start.line,
      column: range.start.column,
      index: range.start.index,
    },
    end: {
      line: range.end.line,
      column: range.end.column,
      index: range.end.index,
    },
  };
};

/**
 * Validate a parsed YAML rule (Effect-TS compliant)
 */
const validateRule = (raw: unknown, filePath: string): Effect.Effect<PatternRule, Error> =>
  Effect.gen(function* () {
    const r = raw as Record<string, unknown>;

    // Access properties via bracket notation for index signatures
    const id = r['id'];
    const language = r['language'];
    const message = r['message'];
    const rule = r['rule'];
    const severity = r['severity'];
    const fix = r['fix'];
    const note = r['note'];
    const constraints = r['constraints'];

    if (!id || typeof id !== 'string') {
      return yield* Effect.fail(new Error(`Rule in ${filePath} missing required 'id' field`));
    }
    if (!language || typeof language !== 'string') {
      return yield* Effect.fail(new Error(`Rule ${id} missing required 'language' field`));
    }
    if (!message || typeof message !== 'string') {
      return yield* Effect.fail(new Error(`Rule ${id} missing required 'message' field`));
    }
    if (!rule || typeof rule !== 'object') {
      return yield* Effect.fail(new Error(`Rule ${id} missing required 'rule' field`));
    }

    // Build the result, only including optional fields if they're defined
    const result: PatternRule = {
      id,
      language: language as PatternLanguage,
      severity: (severity as RuleSeverity | undefined) ?? 'error',
      message,
      rule: rule as RuleConfig,
    };

    // Add optional fields only if present (exactOptionalPropertyTypes compliance)
    if (typeof fix === 'string') {
      (result as { fix: string }).fix = fix;
    }
    if (typeof note === 'string') {
      (result as { note: string }).note = note;
    }
    if (constraints !== undefined && typeof constraints === 'object') {
      (result as { constraints: Record<string, ConstraintConfig> }).constraints =
        constraints as Record<string, ConstraintConfig>;
    }

    return result;
  });

/**
 * Create a PatternMatch object with optional fix (exactOptionalPropertyTypes compliant)
 */
const createMatch = (
  rule: PatternRule,
  node: SgNode,
  captures: Record<string, string>
): PatternMatch => {
  const match: PatternMatch = {
    rule: rule.id,
    severity: rule.severity,
    message: rule.message,
    node: {
      text: node.text(),
      range: toSourceRange(node),
      kind: String(node.kind()),
    },
    captures,
  };

  // Add fix only if present (exactOptionalPropertyTypes compliance)
  if (rule.fix) {
    (match as { fix: PatternFix }).fix = {
      replacement: interpolateFix(rule.fix, node),
      description: rule.message,
    };
  }

  return match;
};

/**
 * Interpolate metavariables in fix template
 */
const interpolateFix = (template: string, node: SgNode): string => {
  let result = template;

  // Replace common metavariables
  const vars = [
    'ARGS',
    'METHOD',
    'NAME',
    'PATH',
    'HANDLER',
    'APP',
    'CONFIG',
    'ARG',
    'CTX',
    'BODY',
    'MSG',
    'ERROR',
  ];
  for (const varName of vars) {
    const match = node.getMatch(varName);
    if (match) {
      // Replace all forms: $$$VAR, $$VAR, $VAR
      result = result.replace(new RegExp(`\\$\\$\\$${varName}`, 'g'), match.text());
      result = result.replace(new RegExp(`\\$\\$${varName}`, 'g'), match.text());
      result = result.replace(new RegExp(`\\$${varName}`, 'g'), match.text());
    }
  }

  // Replace $MATCH with the full matched text
  result = result.replace(/\$MATCH/g, node.text());

  return result;
};

// =============================================================================
// Live Implementation (Adapter)
// =============================================================================

/**
 * Create the live PatternEngine service implementation
 */
const makePatternService = (): PatternService => ({
  parseSource: (content: string, language: PatternLanguage) =>
    Effect.try({
      try: () => parse(mapLanguage(language), content),
      catch: (e) => new Error(`Failed to parse source as ${language}: ${e}`),
    }),

  findPattern: (root: SgRoot, pattern: string) =>
    Effect.try({
      try: () => {
        const sgRoot = root.root();
        return sgRoot.findAll(pattern);
      },
      catch: (e) => new Error(`Pattern search failed for '${pattern}': ${e}`),
    }),

  applyRule: (root: SgRoot, rule: PatternRule, _filePath?: string) =>
    Effect.try({
      try: () => {
        const matches: PatternMatch[] = [];
        const sgRoot = root.root();

        // Handle pattern-based rules (most common)
        if (rule.rule.pattern) {
          let nodes = sgRoot.findAll(rule.rule.pattern);

          // Apply 'not' filter if present
          if (rule.rule.not?.inside?.pattern) {
            nodes = nodes.filter((node) => {
              // Check if node is NOT inside the excluded pattern
              let parent = node.parent();
              while (parent) {
                if (parent.matches(rule.rule.not?.inside?.pattern ?? '')) {
                  return false; // Exclude this node
                }
                parent = parent.parent();
              }
              return true; // Keep this node
            });
          }

          for (const node of nodes) {
            matches.push(createMatch(rule, node, extractCaptures(node)));
          }
        }

        // Handle kind-based rules
        if (rule.rule.kind && !rule.rule.pattern) {
          const nodes = sgRoot.findAll({ rule: { kind: rule.rule.kind } });
          for (const node of nodes) {
            // Apply regex filter if present
            if (rule.rule.regex) {
              const regex = new RegExp(rule.rule.regex);
              if (!regex.test(node.text())) continue;
            }

            matches.push(createMatch(rule, node, extractCaptures(node)));
          }
        }

        return matches;
      },
      catch: (e) => new Error(`Rule application failed for '${rule.id}': ${e}`),
    }),

  applyRules: (
    content: string,
    language: PatternLanguage,
    rules: readonly PatternRule[],
    filePath?: string
  ) =>
    Effect.gen(function* () {
      const root = yield* Effect.try({
        try: () => parse(mapLanguage(language), content),
        catch: (e) => new Error(`Failed to parse source: ${e}`),
      });

      const allMatches: PatternMatch[] = [];

      for (const rule of rules) {
        // Skip rules for different languages
        if (rule.language !== language) continue;

        const matches = yield* Effect.try({
          try: () => {
            const result: PatternMatch[] = [];
            const sgRoot = root.root();

            if (rule.rule.pattern) {
              const nodes = sgRoot.findAll(rule.rule.pattern);
              for (const node of nodes) {
                result.push(createMatch(rule, node, extractCaptures(node)));
              }
            }

            return result;
          },
          catch: (e) => new Error(`Rule ${rule.id} failed: ${e}`),
        });

        allMatches.push(...matches);
      }

      return {
        filePath: filePath ?? '<unknown>',
        matches: allMatches,
        hasErrors: allMatches.some((m) => m.severity === 'error'),
        hasWarnings: allMatches.some((m) => m.severity === 'warning'),
      };
    }),

  loadRuleFromYaml: (path: string) =>
    Effect.gen(function* () {
      const content = yield* Effect.tryPromise({
        try: () => readFile(path, 'utf-8'),
        catch: (e) => new Error(`Failed to read rule file ${path}: ${e}`),
      });
      const parsed = parseYaml(content);
      return yield* validateRule(parsed, path);
    }),

  loadRulesFromDirectory: (dirPath: string) =>
    Effect.gen(function* () {
      const rules: PatternRule[] = [];

      // Recursively find all .yml files
      const findYamlFiles = async (dir: string): Promise<string[]> => {
        const files: string[] = [];
        const entries = await readdir(dir, { withFileTypes: true });

        for (const entry of entries) {
          const fullPath = join(dir, entry.name);
          if (entry.isDirectory()) {
            files.push(...(await findYamlFiles(fullPath)));
          } else if (entry.name.endsWith('.yml') || entry.name.endsWith('.yaml')) {
            files.push(fullPath);
          }
        }

        return files;
      };

      const yamlFiles = yield* Effect.tryPromise({
        try: () => findYamlFiles(dirPath),
        catch: (e) => new Error(`Failed to scan directory ${dirPath}: ${e}`),
      });

      for (const file of yamlFiles) {
        const ruleEffect = Effect.gen(function* () {
          const content = yield* Effect.tryPromise({
            try: () => readFile(file, 'utf-8'),
            catch: (e) => new Error(`Failed to read ${file}: ${e}`),
          });
          const parsed = parseYaml(content);
          return yield* validateRule(parsed, file);
        });

        // Try to load rule, log warning on failure but continue
        const result = yield* Effect.either(ruleEffect);
        if (result._tag === 'Right') {
          rules.push(result.right);
        } else {
          console.warn(`Warning: Could not load rule from ${file}: ${result.left.message}`);
        }
      }

      return rules;
    }),

  applyFix: (content: string, match: PatternMatch) =>
    Effect.try({
      try: () => {
        if (!match.fix) {
          return content;
        }

        const { start, end } = match.node.range;
        return content.slice(0, start.index) + match.fix.replacement + content.slice(end.index);
      },
      catch: (e) => new Error(`Failed to apply fix for ${match.rule}: ${e}`),
    }),

  applyAllFixes: (content: string, matches: readonly PatternMatch[]) =>
    Effect.try({
      try: () => {
        // Filter to matches with fixes and sort by position (reverse order to preserve offsets)
        const fixableMatches = [...matches]
          .filter((m) => m.fix)
          .sort((a, b) => b.node.range.start.index - a.node.range.start.index);

        let result = content;
        for (const match of fixableMatches) {
          if (match.fix) {
            const { start, end } = match.node.range;
            result = result.slice(0, start.index) + match.fix.replacement + result.slice(end.index);
          }
        }

        return result;
      },
      catch: (e) => new Error(`Failed to apply fixes: ${e}`),
    }),
});

// =============================================================================
// Live Layer
// =============================================================================

/**
 * PatternEngineLive - the live Layer providing the PatternEngine service
 */
export const PatternEngineLive = Layer.succeed(PatternEngine, makePatternService());

// =============================================================================
// Convenience Functions (for use with Effect.provide)
// =============================================================================

/**
 * Parse source code into an ast-grep root - requires PatternEngine in context
 */
export const parseSource = (
  content: string,
  language: PatternLanguage
): Effect.Effect<SgRoot, Error, PatternEngine> =>
  Effect.flatMap(PatternEngine, (engine) => engine.parseSource(content, language));

/**
 * Find all nodes matching a pattern - requires PatternEngine in context
 */
export const findPattern = (
  root: SgRoot,
  pattern: string
): Effect.Effect<readonly SgNode[], Error, PatternEngine> =>
  Effect.flatMap(PatternEngine, (engine) => engine.findPattern(root, pattern));

/**
 * Apply a rule to a parsed root - requires PatternEngine in context
 */
export const applyRule = (
  root: SgRoot,
  rule: PatternRule,
  filePath?: string
): Effect.Effect<readonly PatternMatch[], Error, PatternEngine> =>
  Effect.flatMap(PatternEngine, (engine) => engine.applyRule(root, rule, filePath));

/**
 * Apply multiple rules to source content - requires PatternEngine in context
 */
export const applyRules = (
  content: string,
  language: PatternLanguage,
  rules: readonly PatternRule[],
  filePath?: string
): Effect.Effect<RuleApplicationResult, Error, PatternEngine> =>
  Effect.flatMap(PatternEngine, (engine) => engine.applyRules(content, language, rules, filePath));

/**
 * Load a rule from YAML file - requires PatternEngine in context
 */
export const loadRuleFromYaml = (path: string): Effect.Effect<PatternRule, Error, PatternEngine> =>
  Effect.flatMap(PatternEngine, (engine) => engine.loadRuleFromYaml(path));

/**
 * Load all rules from a directory - requires PatternEngine in context
 */
export const loadRulesFromDirectory = (
  dirPath: string
): Effect.Effect<readonly PatternRule[], Error, PatternEngine> =>
  Effect.flatMap(PatternEngine, (engine) => engine.loadRulesFromDirectory(dirPath));

/**
 * Apply a single fix - requires PatternEngine in context
 */
export const applyFix = (
  content: string,
  match: PatternMatch
): Effect.Effect<string, Error, PatternEngine> =>
  Effect.flatMap(PatternEngine, (engine) => engine.applyFix(content, match));

/**
 * Apply all fixes - requires PatternEngine in context
 */
export const applyAllFixes = (
  content: string,
  matches: readonly PatternMatch[]
): Effect.Effect<string, Error, PatternEngine> =>
  Effect.flatMap(PatternEngine, (engine) => engine.applyAllFixes(content, matches));
