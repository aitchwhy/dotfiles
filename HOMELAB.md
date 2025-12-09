# HOMELAB.md

> **Remote Claude Code Development Infrastructure Specification**
>
> A world-class, self-hosted cloud development environment for running Claude Code and compute-intensive LLM workloads remotely.

---

## Table of Contents

1. [Overview](#overview)
2. [User Decisions](#user-decisions)
3. [Current System Audit](#current-system-audit)
4. [Cloud Provider Comparison](#cloud-provider-comparison)
5. [NixOS Configuration Strategy](#nixos-configuration-strategy)
6. [Claude Code Remote Architecture](#claude-code-remote-architecture)
7. [Networking & Access Patterns](#networking--access-patterns)
8. [GPU & LLM Infrastructure](#gpu--llm-infrastructure)
9. [Development Environment Platforms](#development-environment-platforms)
10. [Data & Storage Strategy](#data--storage-strategy)
11. [Security & Secrets Management](#security--secrets-management)
12. [Agentic Systems Integration](#agentic-systems-integration)
13. [Implementation Roadmap](#implementation-roadmap)
14. [Cost Analysis](#cost-analysis)
15. [References](#references)
16. [Version History](#version-history)

---

## Overview

This document specifies a cloud development infrastructure designed for:

| Priority | Description |
|----------|-------------|
| **Full Ownership** | Own all infrastructure, data, and processes |
| **Environment Parity** | Identical setup between local macOS and cloud NixOS |
| **SSH Accessibility** | Access from Terminal.app, Termius, iPad, phone |
| **Persistent Sessions** | Survive disconnections and network changes |
| **GPU Acceleration** | LLM inference workloads (Phase 2) |
| **Declarative Config** | Nix Flakes for reproducibility |

---

## User Decisions

*Captured: December 7, 2025*

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Usage Pattern** | Always-on dev server | 24/7 accessible, ~$20-40/mo |
| **Region** | US East (iad/ord) | Best GPU availability for future expansion |
| **GPU Strategy** | CPU-only to start | Add Fly.io L40S when needed |
| **Secrets** | sops-nix + age | Encrypted in Git, decrypted at deploy |

---

## Current System Audit

### System Information

| Property | Value |
|----------|-------|
| **OS** | macOS 26.1 (Tahoe) Build 25B78 |
| **Kernel** | Darwin 25.1.0 |
| **Architecture** | Apple M4 (arm64 / aarch64-darwin) |
| **Hostname** | `hank-mbp-m4` |

### Dotfiles Architecture

**Repository**: `/Users/hank/dotfiles`
**Stats**: 54 Nix files, ~4,000 lines

```
/Users/hank/dotfiles/
├── flake.nix                    # Main entry point
├── flake.lock                   # Version pinning
├── justfile                     # Task automation
├── modules/
│   ├── nixpkgs.nix             # Nix settings + binary caches
│   ├── homebrew.nix            # GUI apps (50+ casks, 32 MAS apps)
│   └── darwin/                 # 14 macOS system modules
│       ├── system.nix          # 60+ macOS defaults
│       ├── dock.nix            # Dock position (left)
│       ├── finder.nix          # Finder preferences
│       ├── keyboard.nix        # Key repeat tuning
│       ├── trackpad.nix        # Touch sensitivity
│       ├── kanata.nix          # Keyboard remapper daemon
│       └── ...
│   └── home/                   # 31 home-manager modules
│       ├── shell/              # zsh, bash, starship, aliases
│       ├── tools/              # git, tmux, zellij, atuin, fzf
│       └── apps/               # ghostty, neovim, claude-code
├── users/hank.nix              # 80+ CLI packages
├── hosts/hank-mbp-m4.nix       # Host-specific config
└── config/                     # Application configs
    ├── claude-code/            # CLAUDE.md, hooks, skills
    ├── nvim/                   # LazyVim 15.x
    ├── ghostty/                # Terminal config
    └── zellij/                 # Multiplexer config
```

### Cross-Platform Modules (~70% Reusable)

- Shell configuration (zsh, starship, aliases)
- Development tools (git, fzf, atuin, direnv)
- Language toolchains (Node.js, Python, Go, Rust)
- Editor configuration (neovim)
- Claude Code configuration (hooks, skills, CLAUDE.md)
- Cloud CLIs (aws, gcloud, azure, flyctl)

### macOS-Only Modules (~30%)

- darwin/* modules (launchd, macOS defaults)
- homebrew.nix (GUI apps)
- Karabiner/Kanata DriverKit
- Window management (AeroSpace, Swish)

---

## Cloud Provider Comparison

| Provider | CPU VMs | GPU VMs | NixOS Support | Bare Metal | Pricing | Best For |
|----------|---------|---------|---------------|------------|---------|----------|
| **Fly.io** | Yes | L40S/A100 | Docker-based | No | Per-second | Edge, fast deploys |
| **Hetzner** | Yes | Yes | Custom ISO | Yes | Monthly | EU, cost efficiency |
| **DigitalOcean** | Yes | H100/H200 | Custom image | Yes | Hourly | Developer UX |
| **Vultr** | Yes | Yes | Custom ISO | Yes | Hourly | Global regions |
| **OVHcloud** | Yes | Yes | Native | Yes | Monthly | EU sovereignty |
| **Lambda Labs** | No | H100/H200 | No | Yes | Hourly | ML training |
| **Vast.ai** | No | Marketplace | No | No | Spot/hourly | Budget GPU |

### Recommended: Vultr High Frequency (US East)

- Best performance/cost balance in US East
- AMD EPYC, 3+ GHz CPUs, NVMe storage
- Easy NixOS custom ISO upload
- $40/mo for 4 vCPU, 8GB RAM, 128GB NVMe

### GPU Recommendation: Fly.io

- L40S at $1.25/hr (48GB VRAM, Ada Lovelace)
- A100 80GB SXM at $3.50/hr
- Per-second billing
- Global edge network

---

## NixOS Configuration Strategy

### Deployment Tool: nixos-anywhere

Remote NixOS installation via SSH with declarative partitioning.

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#cloud \
  root@<ip-address>
```

### Flake Extension

```nix
# Addition to flake.nix outputs
nixosConfigurations.cloud = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit inputs self; };
  modules = [
    ./hosts/cloud/hardware-configuration.nix
    ./hosts/cloud/configuration.nix
    ./modules/nixpkgs.nix
    ./modules/nixos/default.nix
    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.hank = import ./users/hank.nix;
      };
    }
  ];
};
```

### New Module Structure

```
modules/nixos/
├── default.nix           # Module aggregator
├── system.nix            # Boot, filesystem, networking
├── security.nix          # Firewall, fail2ban
├── users.nix             # User accounts
└── services/
    ├── sshd.nix          # Hardened SSH config
    ├── tailscale.nix     # Zero-trust networking
    ├── docker.nix        # Container runtime
    └── claude-daemon.nix # Claude Code background service
```

### Disk Configuration (disko)

```nix
# hosts/cloud/disk-config.nix
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; };
          };
          root = {
            size = "100%";
            content = { type = "filesystem"; format = "ext4"; mountpoint = "/"; };
          };
        };
      };
    };
  };
}
```

---

## Claude Code Remote Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    LOCAL DEVICE (macOS/iOS)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Terminal.app │  │   Termius    │  │   VS Code    │      │
│  │ (SSH client) │  │ (iOS/Android)│  │ (Remote SSH) │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
└─────────┼─────────────────┼─────────────────┼───────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                     TAILSCALE MESH VPN                      │
│              (Zero-trust, WireGuard-based)                  │
│         - No port forwarding required                       │
│         - Encrypted peer-to-peer connections                │
│         - Magic DNS: cloud.tailnet.ts.net              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    CLOUD VM (NixOS)                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   systemd services                    │  │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────────┐   │  │
│  │  │  sshd      │ │ tailscaled │ │ docker/podman  │   │  │
│  │  └────────────┘ └────────────┘ └────────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              PERSISTENT SESSIONS                      │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │                  ZELLIJ                         │  │  │
│  │  │  ┌─────────┐ ┌─────────┐ ┌─────────────────┐  │  │  │
│  │  │  │ Claude  │ │  nvim   │ │   shell         │  │  │  │
│  │  │  │  Code   │ │         │ │                 │  │  │  │
│  │  │  └─────────┘ └─────────┘ └─────────────────┘  │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   ~/dotfiles                          │  │
│  │  - CLAUDE.md, skills, hooks (symlinked)              │  │
│  │  - ~/.claude/ configuration                          │  │
│  │  - Identical to local environment                    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Session Persistence Strategy

| Tool | Purpose | Usage |
|------|---------|-------|
| **Zellij** | Primary multiplexer | `zellij attach dev` |
| **Mosh** | UDP-based for flaky connections | `mosh cloud` |
| **tmux** | Fallback | `tmux attach -t main` |
| **Claude Code `-c`** | Resume sessions | `claude -c` |

### SSH Hardening

```nix
# modules/nixos/services/sshd.nix
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
    PubkeyAuthentication = true;
    X11Forwarding = false;
  };
  extraConfig = ''
    AllowUsers hank
    MaxAuthTries 3
    ClientAliveInterval 300
    ClientAliveCountMax 2
  '';
};
```

### Claude Code Headless Mode

```bash
# Run with persistent session
zellij attach claude-session || zellij -s claude-session

# Headless execution
claude -p "analyze this codebase" --output-format stream-json

# Resume interrupted session
claude -c
```

---

## Networking & Access Patterns

### Primary: Tailscale

- Free for personal use (100 devices)
- WireGuard-based encryption
- NAT traversal without port forwarding
- Magic DNS: `ssh hank@cloud`

### Self-Hosted Alternative: Headscale

- Open-source Tailscale control server
- Full infrastructure ownership
- Compatible with official clients

### Tailscale NixOS Module

```nix
# modules/nixos/services/tailscale.nix
services.tailscale = {
  enable = true;
  useRoutingFeatures = "both";
  authKeyFile = "/run/secrets/tailscale-auth";
};

networking.firewall = {
  trustedInterfaces = [ "tailscale0" ];
  allowedUDPPorts = [ 41641 ];
};
```

### Access Matrix

| Device | Method | Command |
|--------|--------|---------|
| macOS Terminal | SSH over Tailscale | `ssh cloud` |
| macOS Termius | Saved connection | One-click |
| iOS Termius | Saved connection | One-click |
| iPad | Termius + keyboard | Full terminal |
| Cursor/VS Code | Remote SSH | `cloud:~/projects` |
| Web browser | Tailscale Funnel | `https://cloud.ts.net` |

---

## GPU & LLM Infrastructure

### Self-Hosted LLM Stack (Phase 2)

```
┌────────────────────────────────────────────────────────────┐
│                   GPU WORKLOAD VM                          │
│                   (Fly.io L40S 48GB)                       │
│                                                            │
│  ┌────────────────────────────────────────────────────┐   │
│  │                    Ollama                           │   │
│  │  - API: http://localhost:11434                     │   │
│  │  - Models: llama-3.3-70b, codellama-34b           │   │
│  │  - NVIDIA driver + CUDA                            │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
│  ┌────────────────────────────────────────────────────┐   │
│  │               vLLM (production)                     │   │
│  │  - OpenAI-compatible API                           │   │
│  │  - Continuous batching                             │   │
│  │  - PagedAttention                                  │   │
│  └────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

### GPU Options

| Use Case | GPU | VRAM | Cost | Provider |
|----------|-----|------|------|----------|
| Light (7B-13B) | RTX 3060 | 12GB | $0.20/hr | Vast.ai |
| Medium (30B-70B) | L40S | 48GB | $1.25/hr | Fly.io |
| Heavy (70B+) | A100 80GB | 80GB | $3.50/hr | Fly.io |
| Training | H100 SXM | 80GB | $4.76/hr | Lambda |

### VRAM Requirements (December 2025)

| Model | Quantization | VRAM |
|-------|--------------|------|
| Llama 3.3 70B | Q4 | ~40GB |
| CodeLlama 34B | Q4 | ~20GB |
| Qwen 2.5 72B | Q4 | ~40GB |
| DeepSeek V3 | Q4 | ~200GB+ |

---

## Development Environment Platforms

### Option A: Direct NixOS VM (Recommended)

- Full control, no abstraction
- Identical environment via Nix
- SSH + Zellij persistence
- Lower cost, maximum flexibility

### Option B: Coder.com

- Enterprise CDE platform
- Terraform-based workspaces
- Web IDE + SSH access
- Better for teams

### Option C: DevPod

- Client-only, no server
- Works with any provider
- Devcontainer.json compatible
- Good for experiments

---

## Data & Storage Strategy

### Directory Structure

```
/home/hank/
├── dotfiles/           # Git-tracked, synced
├── projects/           # Active development
│   └── ember/          # Main project
├── .claude/            # Claude Code state
│   ├── settings.json   # From dotfiles
│   └── sessions/       # Local state
└── .local/share/       # Application data
    ├── atuin/          # Shell history (synced)
    └── ollama/         # LLM models
```

### Backup Strategy

| Data | Method | Frequency |
|------|--------|-----------|
| Dotfiles | Git push | On change |
| Projects | Git + rsync | Daily |
| VM State | Volume snapshots | Weekly |
| LLM Models | Re-downloadable | N/A |

---

## Security & Secrets Management

### sops-nix Configuration

```nix
# Add to flake.nix inputs
inputs.sops-nix.url = "github:Mic92/sops-nix";

# modules/nixos/secrets.nix
sops = {
  defaultSopsFile = ./secrets/secrets.yaml;
  age.keyFile = "/var/lib/sops-nix/key.txt";
  secrets = {
    tailscale-auth = { };
    github-token = { };
    anthropic-api-key = { };
  };
};
```

### Security Hardening Checklist

- [x] SSH key-only authentication
- [x] Fail2ban for brute-force protection
- [x] Firewall (only Tailscale allowed)
- [x] Automatic security updates
- [x] Encrypted secrets in Git (sops + age)
- [x] No root SSH access
- [x] No password authentication

---

## Agentic Systems Integration

### Claude Code Ecosystem (December 2025)

| Tool | Type | Best For |
|------|------|----------|
| **Claude Code** | CLI Agent | Terminal-first, autonomous |
| **Cursor** | IDE + Agent | Visual, multi-file |
| **Windsurf** | IDE + Agent | Session memory |
| **Kiro** | IDE + Agent | Spec-driven |
| **Gemini CLI** | CLI Agent | 1M token context |

### Claude Code Configuration (Cloud Parity)

```
~/.claude/
├── CLAUDE.md            # → ~/dotfiles/config/claude-code/CLAUDE.md
├── settings.json        # Merged from dotfiles
├── commands/            # → ~/dotfiles/config/claude-code/commands/
├── skills/              # → ~/dotfiles/config/claude-code/skills/
└── agents/              # → ~/dotfiles/config/claude-code/agents/
```

### Hooks (Enforced on Cloud)

| Hook | Purpose |
|------|---------|
| TDD Enforcer | Blocks source edits without tests |
| Assumption Detector | Blocks "should" language |
| Verification Gate | Requires test evidence |
| Auto-formatters | biome, ruff, alejandra, shfmt |

### MCP Servers

```json
{
  "memory": { "command": "npx", "args": ["@modelcontextprotocol/server-memory"] },
  "filesystem": { "command": "npx", "args": ["@modelcontextprotocol/server-filesystem", "/home/hank"] },
  "sequential-thinking": { "command": "npx", "args": ["@modelcontextprotocol/server-sequential-thinking"] },
  "context7": { "command": "npx", "args": ["@upstash/context7-mcp"] }
}
```

---

## Implementation Roadmap

### Phase 1: Foundation ✅ Complete

- [x] Add sops-nix to flake.nix inputs
- [x] Add NixOS configuration to flake.nix outputs
- [x] Create `modules/nixos/` directory structure
- [x] Create `hosts/cloud/` configuration
- [x] Extract cross-platform modules (users/hank-linux.nix)

### Phase 2: Infrastructure (Day 2-3)

- [ ] Provision Vultr droplet in US East
- [ ] Deploy NixOS via nixos-anywhere + disko
- [ ] Configure sops-nix for secrets
- [ ] Configure Tailscale networking
- [ ] Test SSH access from all devices

### Phase 3: Environment (Day 4-5)

- [ ] Clone dotfiles to cloud VM
- [ ] Run home-manager switch
- [ ] Verify Claude Code with hooks/skills
- [ ] Configure Zellij persistence
- [ ] Test mosh for unstable connections

### Phase 4: GPU (Future)

- [ ] Provision Fly.io L40S (US East/ord)
- [ ] Install Ollama + models
- [ ] Configure API access
- [ ] Add to Tailscale network

### Phase 5: Automation (Ongoing)

- [ ] GitHub Actions for deployments
- [ ] Automated volume snapshots
- [ ] Uptime monitoring
- [ ] Runbook documentation

---

## Cost Analysis

### Phase 1: CPU-Only

| Resource | Provider | Spec | Cost |
|----------|----------|------|------|
| Dev VM | Vultr | 4 vCPU, 8GB RAM | ~$40/mo |
| Dev VM | Hetzner | 4 vCPU, 16GB RAM | ~$20/mo |
| Tailscale | Free tier | 100 devices | $0 |
| sops-nix | Self-managed | Secrets | $0 |
| **Total** | | | **~$20-40/mo** |

### Phase 2: With GPU

| Resource | Provider | Spec | Cost |
|----------|----------|------|------|
| GPU VM | Fly.io | L40S 48GB | $1.25/hr |
| 20 hrs/month | Fly.io | Estimated | ~$25/mo |
| **Additional** | | | **+$25-50/mo** |

---

## References

### Cloud Infrastructure

- [Fly.io GPU Pricing](https://fly.io/docs/gpus/)
- [Hetzner Cloud](https://www.hetzner.com/cloud)
- [Vultr High Frequency](https://www.vultr.com/)

### NixOS Deployment

- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- [disko](https://github.com/nix-community/disko)
- [sops-nix](https://github.com/Mic92/sops-nix)

### Claude Code Remote

- [Claude Code Headless Mode](https://code.claude.com/docs/en/headless)
- [Remote SSH Tunnel Guide](https://compiledthoughts.pages.dev/blog/claude-code-remote-ssh-tunnel/)
- [ShellHub Integration](https://dev.to/gustavosbarreto/remote-ai-coding-with-claude-code-and-shellhub-25)

### Networking

- [Tailscale SSH](https://tailscale.com/kb/1193/tailscale-ssh/)
- [Headscale](https://github.com/juanfont/headscale)

### GPU/LLM

- [Best GPU for LLM Inference 2025](https://compute.hivenet.com/post/best-gpu-for-llm-inference-2025)
- [Self-Hosted LLM Guide](https://www.virtualizationhowto.com/2025/10/best-self-hosted-ai-tools-you-can-actually-run-in-your-home-lab/)

### Development Environments

- [Coder.com](https://coder.com/)
- [DevPod](https://devpod.sh/)
- [Gitpod/Ona](https://www.gitpod.io/)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-07 | Initial specification |

---

*Generated: December 7, 2025*
*Repository: github.com/hank/dotfiles*
