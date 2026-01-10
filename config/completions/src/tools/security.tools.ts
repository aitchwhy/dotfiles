/**
 * Security & Secrets Tools
 */
import type { CliTool } from "../schemas";
import { nixTool } from "../schemas";

export const securityTools: readonly CliTool[] = [
  nixTool("sops", "sops", "security", "sops", "Secrets management"),
  nixTool("age", "age", "security", "age", "Encryption tool"),
  nixTool("gnupg", "gpg", "security", "gnupg", "GPG signing"),
  nixTool("bitwarden-cli", "bw", "security", "bitwarden-cli", "Password manager CLI"),
] as const;
