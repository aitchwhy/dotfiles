/**
 * Signet Policy as Code
 *
 * Export all policy packs for use with `pulumi up --policy-pack`.
 *
 * NOTE: PolicyPack instances are created on import, which calls process.exit
 * in non-Pulumi environments. Only import these when running actual Pulumi
 * operations, not during test discovery.
 */

// Re-export policy types for type-safe usage
export type { PolicyPack } from '@pulumi/policy';

/**
 * Lazy-load policy packs to avoid process.exit during test imports.
 * Use these getters when you need the actual PolicyPack instances.
 */
export const getPolicyPacks = async () => {
  const { versionPolicies } = await import('./version-policy');
  const { hexagonalPolicies } = await import('./hexagonal-policy');
  const { effectPolicies } = await import('./effect-policy');
  return { versionPolicies, hexagonalPolicies, effectPolicies };
};
