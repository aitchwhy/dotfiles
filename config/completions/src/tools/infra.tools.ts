/**
 * Infrastructure as Code Tools
 */
import type { CliTool } from "../schemas";
import { nixTool } from "../schemas";

export const infraTools: readonly CliTool[] = [
  nixTool("pulumi", "pulumi", "infra", "pulumi", "Infrastructure as Code"),
  nixTool("pulumi-esc", "esc", "infra", "pulumi-esc", "Pulumi ESC secrets/config"),
] as const;
