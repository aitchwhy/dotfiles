#!/usr/bin/env bun
/**
 * Validate Ports - PreToolUse hook for port registry enforcement
 *
 * Provides advisory guidance (NEVER blocks) when:
 * 1. Nix files contain hardcoded port numbers not from lib/ports.nix
 * 2. process-compose.yaml contains port numbers not in registry
 *
 * Philosophy: All ports should be defined in lib/ports.nix for:
 * - Single source of truth
 * - Port conflict prevention
 * - Easy service discovery
 *
 * Trigger: Write|Edit on modules/*.nix or process-compose.yaml
 */

import { z } from 'zod';

// ============================================================================
// Input Types (TypeScript first, schema satisfies type)
// ============================================================================

type HookInput = {
  readonly hook_event_name: 'PreToolUse';
  readonly session_id: string;
  readonly tool_name: string;
  readonly tool_input: {
    readonly file_path?: string;
    readonly content?: string;
    readonly new_string?: string;
    readonly [key: string]: unknown;
  };
};

const HookInputSchema = z.object({
  hook_event_name: z.literal('PreToolUse'),
  session_id: z.string(),
  tool_name: z.string(),
  tool_input: z
    .object({
      file_path: z.string().optional(),
      content: z.string().optional(),
      new_string: z.string().optional(),
    })
    .passthrough(),
}) satisfies z.ZodType<HookInput>;

// ============================================================================
// Port Registry (sync with lib/ports.nix)
// ============================================================================

// Known ports from lib/ports.nix - keep in sync manually
// Run: nix eval -f lib/ports.nix --json | jq -r '.. | numbers' | sort -un
const KNOWN_PORTS = new Set([
  // infrastructure
  22, // ssh
  41641, // tailscale
  9100, // nodeExporter
  9080, // promtail
  // databases
  6379, // redis
  5432, // postgresql
  7233, // temporal
  // development
  3000, // api
  3001, // worker
  8233, // temporalUI
  // otel
  4317, // grpc
  4318, // http
  // observability
  9090, // prometheus
  3100, // grafana
  3200, // loki
]);

// ============================================================================
// Port Detection Patterns
// ============================================================================

// Patterns for Nix files
const NIX_PORT_PATTERNS = [
  /\bport\s*=\s*(\d{2,5})\b/gi,
  /\blistenPort\s*=\s*(\d+)\b/gi,
  /allowedTCPPorts\s*=\s*\[\s*([^\]]+)\]/gi,
  /allowedUDPPorts\s*=\s*\[\s*([^\]]+)\]/gi,
  /:\s*(\d{2,5})(?:\/tcp|\/udp)/gi, // ExposedPorts style
  /localhost:(\d{2,5})/gi,
];

// Patterns for YAML files
const YAML_PORT_PATTERNS = [
  /--port[=\s]+(\d+)/gi,
  /PORT[=:]\s*["']?(\d+)["']?/gi,
  /-p\s+(\d+):\d+/gi,
  /:\s*(\d{4,5})\s*$/gm,
];

// ============================================================================
// Port Extraction
// ============================================================================

function extractPorts(content: string, patterns: RegExp[]): number[] {
  const ports: number[] = [];

  for (const pattern of patterns) {
    // Reset lastIndex for global patterns
    pattern.lastIndex = 0;
    const regex = new RegExp(pattern.source, pattern.flags);

    let match: RegExpExecArray | null;
    while ((match = regex.exec(content)) !== null) {
      if (match[1]) {
        // Handle space/comma-separated port lists
        const portStrings = match[1].split(/[\s,]+/);
        for (const ps of portStrings) {
          const port = parseInt(ps.trim(), 10);
          if (!isNaN(port) && port >= 1 && port <= 65535) {
            ports.push(port);
          }
        }
      }
    }
  }

  return [...new Set(ports)]; // Dedupe
}

// ============================================================================
// Advisory Message Generation
// ============================================================================

function checkPorts(content: string, filePath: string): string[] {
  const warnings: string[] = [];

  const isNix = filePath.endsWith('.nix');
  const isYaml = filePath.endsWith('.yaml') || filePath.endsWith('.yml');
  const isModuleFile = filePath.includes('/modules/') || filePath.includes('/services/');
  const isProcessCompose = filePath.includes('process-compose');

  // Only check relevant files
  if (!isModuleFile && !isProcessCompose) {
    return warnings;
  }

  const patterns = isNix ? NIX_PORT_PATTERNS : isYaml ? YAML_PORT_PATTERNS : [];
  const foundPorts = extractPorts(content, patterns);

  // Find unknown ports
  const unknownPorts = foundPorts.filter((p) => !KNOWN_PORTS.has(p));

  if (unknownPorts.length > 0) {
    warnings.push(
      `Port(s) ${unknownPorts.join(', ')} not in lib/ports.nix. ` +
        `Add to registry or use ports.* reference.`
    );
  }

  // Suggest import pattern for Nix files with ports
  if (isNix && foundPorts.length > 0) {
    if (!content.includes('ports.') && !content.includes('lib/ports')) {
      warnings.push(
        'Consider: let ports = import ../../../lib/ports.nix; in { ... } ' +
          'for type-safe port references.'
      );
    }
  }

  return warnings;
}

// ============================================================================
// Output Helpers
// ============================================================================

function approve(reason?: string): void {
  console.log(JSON.stringify({ decision: 'approve', reason }));
}

// ============================================================================
// Main Hook Logic
// ============================================================================

async function main(): Promise<void> {
  let rawInput: string;
  try {
    rawInput = await Bun.stdin.text();
  } catch {
    approve();
    return;
  }

  if (!rawInput.trim()) {
    approve();
    return;
  }

  let input: HookInput;
  try {
    input = HookInputSchema.parse(JSON.parse(rawInput));
  } catch {
    approve();
    return;
  }

  const { tool_name, tool_input } = input;
  const filePath = tool_input.file_path || '';
  const content = tool_input.content || tool_input.new_string || '';

  // Only validate Write/Edit operations with file paths
  if (!['Write', 'Edit'].includes(tool_name) || !filePath || !content) {
    approve();
    return;
  }

  const warnings = checkPorts(content, filePath);

  // ALWAYS approve - advisory only, never block
  if (warnings.length > 0) {
    approve(`Port registry guidance: ${warnings.join(' | ')}`);
  } else {
    approve();
  }
}

main().catch((e) => {
  console.error('Validate Ports error:', e);
  approve(); // Fail-open
});
