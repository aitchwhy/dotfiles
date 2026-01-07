---
status: accepted
date: 2026-01-07
decision-makers: [hank]
consulted: []
informed: []
---

# Network and API Development Toolkit

## Context and Problem Statement

How should we provide comprehensive network diagnostics and API development tools while maintaining the "minimal tools, maximal coverage" philosophy?

## Decision Drivers

* Minimal tools - one tool per unique purpose, no redundancy
* SOTA January 2026 - Rust-based CLI tools where possible
* Apple Silicon native performance
* CLI + GUI coverage for different workflows

## Considered Options

* Charles Proxy + Postman + nmap + mtr + dig + httpie (legacy stack)
* Proxyman + yaak + Rust CLI tools (modern SOTA)
* mitmproxy + Bruno + traditional tools (open-source only)

## Decision Outcome

Chosen option: "Proxyman + yaak + Rust CLI tools", because:
- 6 CLI tools + 2 GUI apps = complete coverage with zero redundancy
- trippy consolidates mtr + traceroute + ping into single tool (3→1)
- xh replaces httpie (Rust, faster, same API)
- Proxyman is SOTA native macOS proxy (SwiftNIO)

### Consequences

* Good: 6 tools cover all network use cases
* Good: trippy consolidates 3 legacy tools into 1
* Good: xh is faster than httpie (Rust implementation)
* Good: Proxyman handles HTTP debugging + OpenAPI generation
* Good: Net -3 packages (9 removed, 6 added)
* Neutral: termshark requires wireshark-cli dependency
* Bad: Proxyman is paid ($79 lifetime) - justified by productivity

### Confirmation

```bash
# Verify network tools installed
which speedtest trippy rustscan bandwhich termshark xh

# Test speedtest
speedtest --version

# Verify Proxyman available
open -a Proxyman
```

## Tool Reference

### CLI Tools (Nix Packages)

| Tool | Package | Purpose | Replaces | Command |
|------|---------|---------|----------|---------|
| speedtest | `ookla-speedtest` | Internet speed | - | `speedtest` |
| trip | `trippy` | Network path | mtr, traceroute, ping | `trip google.com` |
| rustscan | `rustscan` | Port scanning | nmap (10x faster) | `rustscan -a 10.0.0.1` |
| bandwhich | `bandwhich` | Bandwidth/process | Activity Monitor | `sudo bandwhich` |
| termshark | `termshark` | Packet inspection | Wireshark GUI | `termshark -i en0` |
| xh | `xh` | HTTP requests | httpie | `xh POST :8080/api` |

### GUI Apps (Homebrew - Already Installed)

| Tool | Cask | Purpose | Features |
|------|------|---------|----------|
| Proxyman | `proxyman` | HTTP proxy | SSL, breakpoints, OpenAPI gen |
| yaak | `yaak` | API collections | Local-first, Git-friendly |

### Existing Tools (Keep)

| Tool | Package | Purpose |
|------|---------|---------|
| grpcurl | `grpcurl` | gRPC testing |
| dig | (coreutils) | DNS queries |
| curl | `curl` | HTTP fallback |

## Coverage Matrix

### By Use Case

| Use Case | Primary Tool | Notes |
|----------|--------------|-------|
| Internet speed test | ookla-speedtest | Official Ookla, 16k+ servers |
| Network path/latency | trippy | Visual TUI, combines 3 tools |
| Port scanning | rustscan | Feeds to nmap for details |
| Bandwidth debugging | bandwhich | Shows per-process usage |
| Packet inspection | termshark | TUI Wireshark |
| HTTP requests | xh | Rust httpie |
| HTTP debugging/proxy | Proxyman | Native macOS, OpenAPI |
| API collections | yaak | Local-first |
| gRPC testing | grpcurl | CLI |
| DNS queries | dig | Built-in |

### By Protocol

| Protocol | Tools |
|----------|-------|
| ICMP | trippy |
| TCP/UDP | rustscan, trippy |
| DNS | dig |
| HTTP/HTTPS | xh, Proxyman |
| gRPC | grpcurl |
| WebSocket | Proxyman |

## OpenAPI Workflow

1. **Record traffic** → Proxyman captures requests automatically
2. **Generate spec** → Proxyman exports OpenAPI 3.x from recorded traffic
3. **Mock responses** → Proxyman Map Local/Remote feature
4. **Validate in code** → Effect HttpApi schema-first validation

## More Information

* Proxyman: https://proxyman.io - Native macOS, SwiftNIO
* trippy: https://github.com/fujiapple852/trippy - Rust TUI network diagnostics
* rustscan: https://github.com/RustScan/RustScan - Fast port scanner
* xh: https://github.com/ducaale/xh - Rust httpie alternative
* Related: [ADR-008](008-nix-managed-config.md) for Nix package management
