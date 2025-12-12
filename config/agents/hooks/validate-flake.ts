#!/usr/bin/env bun
/**
 * Validate Flake - PreToolUse hook for flake.nix
 *
 * Provides warnings (not blocks) when writing flake.nix files
 * that don't follow December 2025 best practices.
 *
 * Trigger: Write(**/flake.nix)
 */

// Read hook input from stdin
const input = JSON.parse(await Bun.stdin.text()) as {
  tool_name: string;
  tool_input: {
    file_path?: string;
    content?: string;
  };
};

const content = input.tool_input?.content || '';
const filePath = input.tool_input?.file_path || '';

// Only validate flake.nix files
if (!filePath.endsWith('flake.nix')) {
  console.log(JSON.stringify({ decision: 'approve' }));
  process.exit(0);
}

const warnings: string[] = [];

// Check for flake-parts pattern (December 2025 standard)
if (!content.includes('flake-parts')) {
  warnings.push('Consider flake-parts for modular composition (see nix-flake-parts skill)');
}

// Check for forAllSystems anti-pattern
if (content.includes('forAllSystems') || content.includes('lib.genAttrs')) {
  warnings.push('forAllSystems is deprecated - use flake-parts perSystem instead');
}

// Check for legacy mkShell without hooks
if (content.includes('mkShell') && !content.includes('pre-commit') && !content.includes('git-hooks')) {
  warnings.push('Consider git-hooks.nix for pre-commit integration');
}

// Check for missing follows
if (content.includes('nix-darwin') && !content.includes('inputs.nixpkgs.follows')) {
  warnings.push('nix-darwin should follow nixpkgs to avoid version drift');
}

// Check for process-compose-flake when process-compose is mentioned
if (
  (content.includes('process-compose') || content.includes('process.compose')) &&
  !content.includes('process-compose-flake')
) {
  warnings.push(
    'Consider process-compose-flake for Nix-native service orchestration (see nix-infrastructure skill)'
  );
}

// Check for lib/ports.nix usage when services are defined
if (
  (content.includes('services') || content.includes('networking.firewall')) &&
  !content.includes('lib/ports') &&
  !content.includes('ports.')
) {
  warnings.push(
    'Consider lib/ports.nix for centralized port registry (see nix-infrastructure skill)'
  );
}

// Check for nix2container when container-related patterns are found
if (
  (content.includes('container') || content.includes('oci') || content.includes('docker')) &&
  !content.includes('nix2container')
) {
  warnings.push('Consider nix2container for OCI image generation (see nix-infrastructure skill)');
}

// Always approve - we only provide guidance, never block
const result = {
  decision: 'approve' as const,
  reason: warnings.length > 0
    ? `Flake guidance: ${warnings.join('; ')}`
    : 'Flake structure OK',
};

console.log(JSON.stringify(result));
