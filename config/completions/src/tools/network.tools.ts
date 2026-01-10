/**
 * Network & API Tools
 */
import type { CliTool } from "../schemas";
import { nixTool } from "../schemas";

export const networkTools: readonly CliTool[] = [
  // Core utilities
  nixTool("curl", "curl", "network", "curl", "HTTP client"),
  nixTool("wget", "wget", "network", "wget", "Download utility"),
  nixTool("xh", "xh", "network", "xh", "Modern HTTP client (Rust)"),

  // Network diagnostics
  nixTool("trippy", "trip", "network", "trippy", "Network path tracer (mtr replacement)"),
  nixTool("rustscan", "rustscan", "network", "rustscan", "Fast port scanner"),
  nixTool("bandwhich", "bandwhich", "network", "bandwhich", "Per-process bandwidth monitor"),
  nixTool("termshark", "termshark", "network", "termshark", "TUI Wireshark"),
  nixTool("speedtest", "speedtest", "network", "ookla-speedtest", "Internet speed test"),
] as const;
