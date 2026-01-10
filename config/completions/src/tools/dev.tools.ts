/**
 * Development Utility Tools
 */
import type { CliTool } from "../schemas";
import { hmTool, nixTool } from "../schemas";

export const devTools: readonly CliTool[] = [
  // Task runners
  nixTool("just", "just", "dev", "just", "Task runner"),
  nixTool("act", "act", "dev", "act", "GitHub Actions local runner"),

  // Data processing
  nixTool("jq", "jq", "dev", "jq", "JSON processor"),
  nixTool("yq", "yq", "dev", "yq", "YAML processor"),

  // Code analysis
  nixTool("ast-grep", "sg", "dev", "ast-grep", "AST-based code search"),

  // System monitoring
  nixTool("btop", "btop", "dev", "btop", "System monitor"),
  nixTool("ncdu", "ncdu", "dev", "ncdu", "Disk usage analyzer"),
  hmTool("htop", "htop", "dev", "programs.htop", "Process viewer"),

  // File management
  hmTool("yazi", "yazi", "dev", "programs.yazi", "File manager TUI"),
  nixTool("watchman", "watchman", "dev", "watchman", "File watcher"),

  // Terminal
  hmTool("zellij", "zellij", "dev", "programs.zellij", "Terminal multiplexer"),
  hmTool("starship", "starship", "dev", "programs.starship", "Shell prompt"),

  // API tools
  nixTool("grpcurl", "grpcurl", "dev", "grpcurl", "gRPC client"),

  // Documentation
  nixTool("glow", "glow", "dev", "glow", "Markdown viewer"),
  nixTool("pandoc", "pandoc", "dev", "pandoc", "Document converter"),
  nixTool("tldr", "tldr", "dev", "tldr", "Community man pages"),

  // Media
  nixTool("ffmpeg", "ffmpeg", "dev", "ffmpeg-full", "Audio/video processing"),
  nixTool("imagemagick", "convert", "dev", "imagemagick", "Image manipulation"),

  // Local dev
  nixTool("mkcert", "mkcert", "dev", "mkcert", "Local HTTPS certs"),
  nixTool("ngrok", "ngrok", "dev", "ngrok", "Expose local servers"),
  nixTool("caddy", "caddy", "dev", "caddy", "Modern web server"),

  // TUI
  nixTool("gum", "gum", "dev", "gum", "TUI components for scripts"),
] as const;
