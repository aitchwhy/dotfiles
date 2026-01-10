/**
 * Kubernetes & Orchestration Tools
 */
import type { CliTool } from "../schemas";
import { nixTool } from "../schemas";

export const kubernetesTools: readonly CliTool[] = [
  nixTool("kubectl", "kubectl", "kubernetes", "kubectl", "Kubernetes CLI"),
  nixTool("kubectx", "kubectx", "kubernetes", "kubectx", "Kubernetes context switcher"),
  nixTool("kubernetes-helm", "helm", "kubernetes", "kubernetes-helm", "Kubernetes package manager"),
  nixTool("k9s", "k9s", "kubernetes", "k9s", "Kubernetes TUI dashboard"),
] as const;
