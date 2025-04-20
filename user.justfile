set unstable := true
# set shell := ["/bin/zsh", "-cu"]

# Common Project Paths
platform_dir := "~/src/platform"
flonotes_fe_dir := "~/src/flonotes-fe"
vibes_dir := "~/src/vibes"
gpt_repo_dir := "~/src/gpt-repository-loader"
# host := `uname -a`

# List available recipes (default file location as cwd)
default:
  just --list 

# Display system information
system-info:
  @echo "CPU architecture: {{ arch() }}"
  @echo "Operating system type: {{ os_family() }}"
  @echo "Operating system: {{ os() }}"
  @echo "Home directory: {{ home_directory() }}"

# --- Default & Utility Recipes ---
# [group('global')]
# choose:
#     @just -- --choose


# [group('global')]
# [working-directory: '~/dotfiles/config/just']
# fmt:
#     @echo "Formatting {{ justfile() }}..."
#     @just --unstable --fmt

# # --- Flonotes / Ant Project Recipes ---
# [group('platform')]
# [working-directory: '~/src/platform']
# noggin-up:
#     @echo "Building and starting Noggin service..."
#     ant build noggin && ant up noggin

# [group('platform')]
# [working-directory: '~/src/platform']
# platform-up:
#     @echo "Building and starting Platform services..."
#     ant build api user s3 prefect-worker prefect-agent prefect-server data-seeder && \
#     ant up api user s3 prefect-worker prefect-agent prefect-server data-seeder

# [group('platform')]
# [working-directory: '~/src/platform']
# platform-otp:
#     @echo "Fetching OTP code from container named 'api'..."
#     @_container_id=$$(docker ps -qf name=api); \
#     if [ -n "$$_container_id" ]; then \
#         docker logs "$$_container_id" 2>&1 | rg "sent an otp code" | tail -n 1; \
#     else \
#         echo "Error: Container 'api' not found."; exit 1; \
#     fi

# [group('platform')]
# [working-directory: '~/src/platform']
# platform-noggin-test:
#     @echo "Running Noggin e2e tests..."
#     docker compose \
#         --profile test-e2e \
#         --file compose.integration.yaml \
#         run \
#         --build \
#         --rm \
#         --env $ANTHROPIC_API_KEY \
#         noggin-test-e2e

# [group('flonotes')]
# [working-directory: '~/src/flonotes-fe']
# flonotes-fe-build:
#     @echo "Deploying Flonotes Frontend locally..."
#     make deploy-local

# # --- Nix Environment Management ---
# [group('nix')]
# [no-cd]
# nix-update-all:
#     @echo "Updating all Nix flake inputs in $(pwd)..."
#     nix flake update

# [group('nix')]
# [no-cd]
# nix-update-input input:
#     @echo "Updating Nix flake input '{{input}}' in $(pwd)..."
#     nix flake update --update-input {{input}}

# [group('nix')]
# nix-history:
#     @echo "Nix system profile history:"
#     nix profile history --profile /nix/var/nix/profiles/system

# [group('nix')]
# [no-cd]
# nix-repl:
#     @echo "Opening Nix REPL for flake in $(pwd)..."
#     nix repl '.#nixpkgs'

# [group('nix')]
# nix-clean-profile:
#     @echo "Cleaning Nix system profile generations older than 7 days..."
#     sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d

# [group('nix')]
# nix-gc:
#     @echo "Running Nix garbage collection (older than 7 days)..."
#     @echo "System GC (requires sudo)..."
#     sudo nix-collect-garbage --delete-older-than 7d
#     @echo "User GC..."
#     nix-collect-garbage --delete-older-than 7d

# [group('nix')]
# [no-cd]
# nix-fmt:
#     @echo "Formatting Nix files in $(pwd)..."
#     nix fmt .

# [group('nix')]
# nix-gcroot:
#     @echo "Nix auto GC roots:"
#     ls -al /nix/var/nix/gcroots/auto/

# # --- Darwin System Management ---
# [private]
# _darwin-set-proxy:
#     @echo "Setting Darwin network proxy (requires sudo)..."
#     sudo python3 {{ justfile_directory() }}/scripts/darwin_set_proxy.py

# [group('darwin')]
# darwin-build: _darwin-set-proxy
#     @echo "Building Darwin configuration for '{{hostname}}'..."
#     nix build ".#darwinConfigurations.{{hostname}}.system" \
#         --extra-experimental-features 'nix-command flakes'
#     @echo "Switching to new Darwin configuration..."
#     ./result/sw/bin/darwin-rebuild switch --flake ".#{{hostname}}"

# [group('darwin')]
# darwin-build-debug: _darwin-set-proxy
#     @echo "Building Darwin configuration for '{{hostname}}' (DEBUG)..."
#     nix build ".#darwinConfigurations.{{hostname}}.system" --show-trace --verbose \
#         --extra-experimental-features 'nix-command flakes'
#     @echo "Switching to new Darwin configuration (DEBUG)..."
#     ./result/sw/bin/darwin-rebuild switch --flake ".#{{hostname}}" --show-trace --verbose

# # --- Utility Functions ---
# [group('utility')]
# system-info:
#     @echo "CPU architecture: {{ arch() }}"
#     @echo "Operating system type: {{ os_family() }}"
#     @echo "Operating system: {{ os() }}"
#     @echo "Home directory: {{ home_directory() }}"
#     @echo "Number of CPUs: {{ num_cpus() }}"

# # Example of parallel jobs recipe (commented out)
# # [group('utility')]
# # parallel-demo:
# #   #!/usr/bin/env -S parallel --shebang --ungroup --jobs {{ num_cpus() }}
# #   echo task 1 start; sleep 3; echo task 1 done
# #   echo task 2 start; sleep 3; echo task 2 done
# #   echo task 3 start; sleep 3; echo task 3 done
# #   echo task 4 start; sleep 3; echo task 4 done

# # --- Homebrew Management ---
# [group('brew')]
# [working-directory: '~/dotfiles']
# brew-bundle:
#     @echo "Installing packages from Brewfile..."
#     brew bundle --file=Brewfile

# # ==============================================================================
# # End of User Justfile
# # ==============================================================================
# # Remember to update the `hostname` variable!
# # Consider creating project-local Justfiles for project-specific recipes.
# # ==============================================================================
