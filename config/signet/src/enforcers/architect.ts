/**
 * Architect Enforcer
 *
 * Validates hexagonal architecture boundaries, circular dependencies,
 * and layer violations. Acts as the architectural guardian.
 */
import { Effect } from 'effect';

// =============================================================================
// Types
// =============================================================================

export interface ArchitectViolation {
  readonly rule: string;
  readonly severity: 'error' | 'warning';
  readonly message: string;
  readonly files?: readonly string[];
  readonly suggestion?: string;
}

export interface ImportEdge {
  readonly from: string;
  readonly to: string;
}

// =============================================================================
// Layer Definitions
// =============================================================================

// Hexagonal architecture layers (outside-in)
const LAYER_ORDER = ['routes', 'middleware', 'app', 'ports', 'adapters', 'lib'] as const;

type Layer = (typeof LAYER_ORDER)[number];

function getLayer(file: string): Layer | null {
  for (const layer of LAYER_ORDER) {
    if (file.includes(`/${layer}/`) || file.includes(`/${layer}.`)) {
      return layer;
    }
  }
  return null;
}

// =============================================================================
// Hexagonal Boundary Checks
// =============================================================================

/**
 * Check that ports don't import from adapters (dependency inversion)
 */
export const checkHexagonalBoundaries = (
  imports: readonly ImportEdge[]
): Effect.Effect<readonly ArchitectViolation[], never> =>
  Effect.succeed(() => {
    const violations: ArchitectViolation[] = [];

    for (const { from, to } of imports) {
      const fromLayer = getLayer(from);
      const toLayer = getLayer(to);

      // Ports should never import from adapters
      if (fromLayer === 'ports' && toLayer === 'adapters') {
        violations.push({
          rule: 'port-imports-adapter',
          severity: 'error',
          message: 'Port imports from adapter - violates dependency inversion',
          files: [from, to],
          suggestion: 'Ports define interfaces; adapters implement them',
        });
      }

      // App should not import from adapters directly
      if (fromLayer === 'app' && toLayer === 'adapters') {
        violations.push({
          rule: 'app-imports-adapter',
          severity: 'warning',
          message: 'App imports directly from adapter - use ports instead',
          files: [from, to],
          suggestion: 'Inject adapter via port interface',
        });
      }
    }

    return violations;
  }).pipe(Effect.flatMap((fn) => Effect.succeed(fn())));

// =============================================================================
// Circular Dependency Detection
// =============================================================================

/**
 * Detect circular dependencies using DFS
 */
export const checkCircularDependencies = (
  imports: readonly ImportEdge[]
): Effect.Effect<readonly ArchitectViolation[], never> =>
  Effect.succeed(() => {
    const violations: ArchitectViolation[] = [];

    // Build adjacency list
    const graph = new Map<string, Set<string>>();
    for (const { from, to } of imports) {
      if (!graph.has(from)) graph.set(from, new Set());
      graph.get(from)!.add(to);
    }

    // DFS to detect cycles
    const visited = new Set<string>();
    const recursionStack = new Set<string>();
    const cycleNodes: string[] = [];

    function dfs(node: string, path: string[]): boolean {
      visited.add(node);
      recursionStack.add(node);
      path.push(node);

      const neighbors = graph.get(node) || new Set();
      for (const neighbor of neighbors) {
        if (!visited.has(neighbor)) {
          if (dfs(neighbor, path)) return true;
        } else if (recursionStack.has(neighbor)) {
          // Found cycle
          const cycleStart = path.indexOf(neighbor);
          cycleNodes.push(...path.slice(cycleStart));
          return true;
        }
      }

      path.pop();
      recursionStack.delete(node);
      return false;
    }

    for (const node of graph.keys()) {
      if (!visited.has(node)) {
        if (dfs(node, [])) {
          violations.push({
            rule: 'circular-dependency',
            severity: 'error',
            message: `Circular dependency detected: ${cycleNodes.join(' → ')}`,
            files: cycleNodes,
            suggestion: 'Break the cycle by extracting shared code to a common module',
          });
          break; // Report only first cycle found
        }
      }
    }

    return violations;
  }).pipe(Effect.flatMap((fn) => Effect.succeed(fn())));

// =============================================================================
// Layer Violation Detection
// =============================================================================

// Allowed import directions (from → to)
// Lower layers can be imported by upper layers
const ALLOWED_IMPORTS: Record<Layer, readonly Layer[]> = {
  routes: ['middleware', 'app', 'ports', 'lib'],
  middleware: ['app', 'ports', 'lib'],
  app: ['ports', 'lib'],
  ports: ['lib'],
  adapters: ['ports', 'lib'],
  lib: [],
};

/**
 * Check for layer violations (wrong import direction)
 */
export const checkLayerViolations = (
  imports: readonly ImportEdge[]
): Effect.Effect<readonly ArchitectViolation[], never> =>
  Effect.succeed(() => {
    const violations: ArchitectViolation[] = [];

    for (const { from, to } of imports) {
      const fromLayer = getLayer(from);
      const toLayer = getLayer(to);

      // Skip if we can't determine layers
      if (!fromLayer || !toLayer) continue;

      // Skip same-layer imports
      if (fromLayer === toLayer) continue;

      const allowed = ALLOWED_IMPORTS[fromLayer];
      if (!allowed.includes(toLayer)) {
        violations.push({
          rule: 'layer-violation',
          severity: 'error',
          message: `Layer violation: ${fromLayer} should not import from ${toLayer}`,
          files: [from, to],
          suggestion: `${fromLayer} can only import from: ${allowed.join(', ') || 'nothing'}`,
        });
      }
    }

    return violations;
  }).pipe(Effect.flatMap((fn) => Effect.succeed(fn())));
