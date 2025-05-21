# Nix Setup in Anterior Platform

This document provides a detailed explanation of the Nix setup in the Anterior Platform, covering the flake.nix file, related Nix files, build processes, and how they connect to the codebase.

## Table of Contents

1. [Overview](#overview)
2. [Key Components](#key-components)
3. [Flake Inputs](#flake-inputs)
4. [Flake Modules](#flake-modules)
5. [Packages and Services](#packages-and-services)
6. [Build Process](#build-process)
7. [Developer Environment](#developer-environment)
8. [Darwin Configuration](#darwin-configuration)
9. [Testing and CI](#testing-and-ci)
10. [Common Commands](#common-commands)

## Overview

The Anterior Platform uses Nix for:

1. **Reproducible Builds**: Ensuring consistent build environments across developers and CI
2. **Service Definition**: Declaratively specifying services and their dependencies
3. **Docker Image Generation**: Creating consistent Docker images for deployment
4. **Development Environments**: Providing standardized developer shells
5. **macOS Configuration**: Managing macOS developer machines via nix-darwin

The central file is `flake.nix`, which defines all inputs, outputs, and modules. The system supports multiple languages (Go, Python, TypeScript/JavaScript) and uses specialized builders for each.

## Key Components

The Nix setup consists of several interconnected components:

### 1. Main Files

- **flake.nix**: The entry point defining inputs, outputs, and system configurations
- **nix/anterior-services.nix**: Defines the service framework for building services
- **nix/anterior-python.nix**: Python-specific configuration using uv2nix
- **nix/anterior-services-process-compose.nix**: Configuration for local service orchestration
- **nix/ant-darwin-module.nix**: macOS configuration for developer machines

### 2. Service Frameworks

The platform uses specialized builders for different language ecosystems:

- **Go**: Using `buildGoModule` with vendor hashes
- **Python**: Using `uv2nix` to build from uv.lock files
- **JavaScript**: Using custom npm2nix implementation

### 3. Build Artifacts

- **Docker Images**: For each service in production and test variants
- **Development Shells**: Language-specific development environments
- **Executables**: Direct access to service binaries

## Flake Inputs

The `flake.nix` file begins by declaring all external dependencies:

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  
  # Terraform providers with specific version pin
  nixpkgs-terraform-providers-bin = {
    url = "github:cohelm/nixpkgs-terraform-providers-bin/18e042762d12cc1e9452e426d4cb1097e7686fb2";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  
  # Pinned to specific version for WeasyPrint compatibility
  nixpkgs_weasyprint_62_3.url = "github:nixos/nixpkgs/29c58cf78dc44b209e40e037b280cbbfc015ef39";
  
  # Nix registry and module system
  flakeregistry = {
    url = "github:NixOS/flake-registry";
    flake = false;
  };
  flake-parts.url = "flake-parts";
  
  # Development shell and service management
  devshell.url = "github:numtide/devshell";
  process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
  services-flake.url = "github:juspay/services-flake";
  
  # Python packaging
  pyproject-nix = {
    url = "github:cohelm/pyproject.nix/fake-sdk-compat";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  uv2nix = {
    url = "github:pyproject-nix/uv2nix";
    inputs.pyproject-nix.follows = "pyproject-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  pyproject-build-systems = {
    url = "github:pyproject-nix/build-system-pkgs";
    inputs.pyproject-nix.follows = "pyproject-nix";
    inputs.uv2nix.follows = "uv2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  
  # macOS configuration
  nix-darwin = {
    url = "nix-darwin";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  
  # Utilities
  globset = {
    url = "github:pdtpartners/globset";
    inputs.nixpkgs-lib.follows = "nixpkgs";
  };
  
  # External services
  brrr = {
    url = "github:cohelm/brrr/v0.1.0";
    inputs.pyproject-build-systems.follows = "pyproject-build-systems";
    inputs.pyproject-nix.follows = "pyproject-nix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.uv2nix.follows = "uv2nix";
  };
  
  # CI tools
  ant-ci-tools.url = "github:cohelm/brrr/ci-tools";
}
```

Key insights:

1. **Input Pinning**: Most inputs are pinned to specific versions or commits
2. **Input Redirection**: Many inputs use `follows` to ensure consistent nixpkgs versions
3. **Custom Forks**: Several inputs are forks maintained by Cohelm (e.g., `cohelm/pyproject.nix`)

## Flake Modules

The flake uses a modular approach with `flake-parts`, which allows splitting configurations into separate modules:

```nix
flake-parts.lib.mkFlake { inherit inputs; } {
  systems = [ "aarch64-linux" "aarch64-darwin" "x86_64-linux" ];
  imports = [
    ./nix/anterior-python.nix
    ./nix/anterior-libpy.nix
    ./nix/anterior-services.nix
    ./nix/anterior-standalones.nix
    inputs.ant-ci-tools.flakeModules.checkBuildAll
    inputs.devshell.flakeModule
    inputs.process-compose-flake.flakeModule
    antFlakeAllSystems
    antFlakeLinux
  ];
}
```

Key modules:

1. **anterior-python.nix**: Configures Python environments using uv2nix
2. **anterior-services.nix**: Defines framework for all services
3. **anterior-standalones.nix**: Builds standalone executables
4. **antFlakeAllSystems**: Cross-platform configuration shared across systems
5. **antFlakeLinux**: Linux-specific configuration for Docker image building

## Packages and Services

The service definitions are collected in `config.anterior.services`, organized by language:

```nix
anterior = {
  inherit python;
  services = {
    python.hello-world = {
      inherit python;
      path = ./services/hello-world;
      subdirectory = "services/hello-world";
    };
    
    go.api = {
      inherit go;
      path = ./services/api;
      subdirectory = "services/api";
      vendorHash = "sha256-8qZAAvhgGHiWkQ6czjNLTtzsz/ftcF/7YqHx6Rps4bg=";
    };
    
    javascript.noggin = {
      inherit nodejs;
      subdirectory = "gateways/noggin";
    };
    
    # Other services...
  };
};
```

Each service declaration specifies:
- **Language**: Python, Go, or JavaScript
- **Path**: Location in the filesystem
- **Subdirectory**: Relative path in the repository
- **Language-specific fields**: Such as vendorHash for Go

### How Services are Built

The service definitions are processed by language-specific builders:

1. **Go Services**:
   - Built using `buildGoModule` 
   - Vendor dependencies are verified with vendorHash
   - Creates both executables and Docker images

2. **Python Services**:
   - Built using uv2nix from uv.lock files
   - Includes virtualenv with all dependencies
   - Containerized with all runtime dependencies

3. **JavaScript Services**:
   - Built using custom npm2nix implementation
   - Handles workspace dependencies
   - Manages native dependencies and prebuilt binaries

## Build Process

### Docker Image Generation

For each service, multiple Docker images are created:

```nix
docker-image-derivs = lib.flatten (lib.mapAttrsToList (name: service: let
  p = service.outputs.package;
in [
  { inherit name; image = p.docker-prod; }
  { name = name + "-test"; image = p.docker-test; }
]) (s.go // s.python // s.javascript));
```

The system creates helper outputs:

1. **all-docker-images**: A file listing all Docker image outputs
2. **all-docker-tags**: Maps service names to Docker image tags
3. **all-docker-derivations**: Maps image names to their derivation paths

### Building Docker Images

When you run `ant-build-docker`, it:

1. Determines which images need to be built
2. Builds them in parallel using Nix
3. Loads them into the local Docker daemon
4. Tags them with `:latest` for use in docker-compose

```nix
command = let
  linuxEquivalent = "${pkgs.hostPlatform.parsed.cpu.name}-linux";
in ''
  build="$(mktemp)"
  tags="$(mktemp)"
  trap "rm -f $build $tags" EXIT
  
  nix build --no-link --print-out-paths .#packages.${linuxEquivalent}.all-docker-derivations | xargs -r cat | while read name drv; do
    if ! docker image inspect "$name" &>/dev/null; then
      printf "%s\t%s^out\n" "$name" "$drv" >> "$build"
    fi
    printf "docker tag %q %q_latest\n" "$name" "${name%_*}" >> "$tags"
  done
  
  <"$build" cut -f 2 | xargs -r nix build --no-link --print-out-paths | xargs -r -n 1 docker load -i
  bash "$tags"
''
```

### Linux Builder for macOS

Since Docker images are Linux-only, macOS developers need a Linux builder to build them. This is configured via nix-darwin:

```nix
nix.linux-builder = {
  config.virtualisation.cores = 6;
  config.virtualisation.memorySize = lib.mkOverride 69 6000;
  config.virtualisation.diskSize = lib.mkForce (100 * 1000);
  maxJobs = 12;
};
```

## Developer Environment

### DevShells

The system provides multiple development shells:

1. **Default Shell**: For repository management and meta-commands
   ```nix
   devshells.default = {
     name = "anterior";
     packages = devPackages { inherit pkgs; };
     motd = ''
       This is a "meta" devshell with commands for managing the
       repository and builds, not so much for actual dev of actual
       features. For an overview of the entire flake, run 'nix flake
       show'.
       
       Services managed by this flake:
       ${items2mdList (
         (map (go: "${go} (go)") (builtins.attrNames config.anterior.services.go))
         ++ (map (py: "${py} (python)") (builtins.attrNames config.anterior.services.python))
         ++ (map (js: "${js} (js)") (builtins.attrNames config.anterior.services.javascript))
       )}
       
       Extra tools on the path:
       ${items2mdList (map (p: "${p.pname or p.name} (${p.version})") packages)}
     '';
     # Commands and environment variables...
   }
   ```

2. **npm Shell**: For JavaScript development
   ```nix
   devShells.npm = pkgs.mkShell {
     name = "anterior-npm-devshell";
     inputsFrom = lib.mapAttrsToList (_: v: v.outputs.package) config.anterior.services.javascript;
     # Configuration...
   };
   ```

3. **Service-Specific Shells**: For each individual service
   - `nix develop .#hello-world`
   - `nix develop .#api`
   - etc.

### Common Commands

The default devshell provides useful commands:

```nix
commands = [
  {
    category = "maintenance";
    name = "system-prune";
    help = "Prune build cache for Docker & Nix";
    # Command implementation...
  }
  {
    name = "ant-admin";
    category = "run";
    help = "Anterior admin tool (/admin)";
    # Command implementation...
  }
  {
    category = "build";
    name = "ant-build-docker";
    help = "Build and load Docker images for every Nix service";
    # Command implementation...
  }
  # Other commands...
];
```

## Darwin Configuration

For macOS developers, the flake provides several nix-darwin configurations:

```nix
darwinConfigurations = {
  anterior-base = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      self.darwinModules.anterior-managed-nixdarwin
      self.darwinModules.anterior-fancy
    ];
  };
  
  anterior-beefy = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      self.darwinModules.anterior-managed-nixdarwin
      self.darwinModules.anterior-fancy
      ({ nix.linux-builder.config.virtualisation.memorySize = lib.mkForce 12000;})
    ];
  };
  
  anterior-bootstrap = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      self.darwinModules.anterior-managed-nixdarwin
      self.darwinModules.anterior-core
    ];
  };
  
  anterior-nobuilder = self.darwinConfigurations.anterior-base.extendModules {
    modules = [
      { nix.linux-builder.enable = lib.mkForce false; }
    ];
  };
};
```

Each configuration serves a specific purpose:
- **anterior-base**: Standard development configuration
- **anterior-beefy**: For machines with more memory (prevents OOM issues)
- **anterior-bootstrap**: Minimal configuration to bootstrap the system
- **anterior-nobuilder**: Configuration without Linux builder for troubleshooting

## Testing and CI

The Nix setup includes testing capabilities:

```nix
checks = {
  lint = pkgs.callPackage ./nix/anterior-lint-ci.nix {
    go-services = let
      all = builtins.attrValues config.anterior.services.go;
    in
      lib.remove config.anterior.services.go.admin all;
    py-services = builtins.attrValues config.anterior.services.python;
    inherit (self'.packages) ruff;
  };
};
```

This enables:
- Running `nix flake check` to verify the repository
- Integrating with CI for automated testing
- Linting Go and Python services

## Local Development with Process Compose

For local development, the platform uses process-compose:

```nix
process-compose.ant-all-services = {
  imports = [
    inputs.services-flake.processComposeModules.default
    inputs.brrr.processComposeModules.dynamodb
    self.processComposeModules.gotenberg
    self.processComposeModules.localstack
    self.processComposeModules.prefect
    ./nix/anterior-services-process-compose.nix
  ];
  services.anterior-platform = {
    enable = true;
    serviceDefinitions = config.anterior.services;
  };
};
```

This enables:
1. Running all services locally with `ant-all-services`
2. Including dependencies like DynamoDB, Localstack, and Prefect
3. Integrating with external services

## Common Commands

Here are the most common commands for working with the Nix system:

### Setup

```bash
# Bootstrap a new macOS machine
darwin-rebuild switch --flake .#anterior-bootstrap

# Switch to full configuration
darwin-rebuild switch --flake .#anterior-base

# Set up Nix cache for faster builds
ant-setup-nix-cache
```

### Building and Running

```bash
# Build Docker images for all services
ant-build-docker

# Run all services locally
ant-all-services

# Run a specific service
nix run .#hello-world

# Enter development shell for a service
nix develop .#hello-world
```

### Development

```bash
# Enter default devshell
nix develop

# Enter npm devshell for JavaScript development
nix develop .#npm

# Lint code
ant-lint

# Clean build caches (use sparingly)
system-prune
```

### Testing

```bash
# Run all checks
nix flake check

# Run a specific service test
cd services/hello-world && pytest
```

## Advanced Features

### Environment Variables

The system sets several environment variables:

```nix
env = [
  {
    name = "ANT_ROOT";
    eval = "$(git rev-parse --show-toplevel)";
  }
  {
    name = "UV_PYTHON_DOWNLOADS";
    value = "never";
  }
  {
    name = "UV_NO_SYNC";
    value = "1";
  }
  {
    name = "SOPS_DISABLE_VERSION_CHECK";
    value = "1";
  }
];
```

### Secrets Management

The system integrates with 1Password for secrets:

```nix
command = ''
  set -euo pipefail
  ${lib.getExe self'.packages.ant-check-1password}
  account=${lib.escapeShellArg _1passwordAccount}
  CACHIX_AUTH_TOKEN="$(op read --account "$account" "op://Engineering/cachix/Envvars/CACHIX_AUTH_TOKEN")"
  export CACHIX_AUTH_TOKEN
  CACHIX_SIGNING_KEY="$(op read --account "$account" "op://Engineering/cachix/Envvars/CACHIX_SIGNING_KEY")"
  export CACHIX_SIGNING_KEY
  cachix use anterior-private
'';
```

## Conclusion

The Nix setup in Anterior Platform provides a comprehensive solution for:

1. **Reproducible Builds**: Ensuring consistency across environments
2. **Service Management**: Declaratively defining and building services
3. **Developer Experience**: Providing tailored development environments
4. **macOS Configuration**: Managing developer machines
5. **Local Development**: Running services locally for testing

The system's modular design allows for easy extension and maintenance, while specialized builders for each language ecosystem ensure optimal builds and deployments.