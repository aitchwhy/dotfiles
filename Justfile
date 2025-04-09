# just is a command runner, Justfile is very similar to Makefile, but simpler.
# TODO update hostname here!

hostname := "your-hostname"

# Flonotes Frontend variables and settings

# List all the just commands
default:
    @just --list

x:
    @just --choose

############################################################################
#
#  Darwin related commands
#
############################################################################

# TODO Feel free to remove this target if you don't need a proxy to speed up the build process
[group('desktop')]
darwin-set-proxy:
    sudo python3 scripts/darwin_set_proxy.py

[group('desktop')]
darwin: darwin-set-proxy
    nix build .#darwinConfigurations.{{ hostname }}.system \
      --extra-experimental-features 'nix-command flakes'

    ./result/sw/bin/darwin-rebuild switch --flake .#{{ hostname }}

[group('desktop')]
darwin-debug: darwin-set-proxy
    nix build .#darwinConfigurations.{{ hostname }}.system --show-trace --verbose \
      --extra-experimental-features 'nix-command flakes'

    ./result/sw/bin/darwin-rebuild switch --flake .#{{ hostname }} --show-trace --verbose

############################################################################
#
# Flonotes Frontend commands
#
############################################################################
# Path variables for Flonotes development

flonotes_platform := "~/src/platform"
flonotes_fe := "~/src/flonotes-fe"


# Setup project
[group('flonotes')]
[working-directory('~/src/flonotes-fe')]
setup:
    ant build
    npm install && npm run build

[group('platform')]
[working-directory('~/src/platform')]
run-noggin: deploy-local
    ant build noggin && ant up noggin

[group('platform')]
[working-directory('~/src/platform')]
run-platform:
    ant build api user s3 prefect-worker prefect-agent prefect-server data-seeder && \
    ant up api user s3 prefect-worker prefect-agent prefect-server data-seeder

# Run the development server with hot reloading
[group('platform')]
[working-directory('~/src/platform')]
run:
    npm run dev --hot

# Test e2e on localhost Docker
[group('platform')]
test-e2e:
    docker compose \
      --profile test-e2e \
      --file compose.integration.yaml \
      run \
      --build \
      --rm \
      --env ANTHROPIC_API_KEY \
      noggin-test-e2e

# Get OTP codes from Docker logs (outputs only the 4-digit code)
[group('platform')]
get-otp:
    docker logs "$(docker container ls | rg 'api' | awk '{print $1}')" | rg "sent an otp code"

# Deploy to local environment
[group('flonotes')]
[working-directory('~/src/flonotes-fe')]
deploy-local:
    make deploy-local

# Deploy to AWS
[group('flonotes')]
deploy-aws profile bucket noggin_url:
    cd {{ flonotes_fe }} && \
    $(pwd)/{{ justfile_directory() }}/scripts/anterior/deploy-aws.sh {{ profile }} {{ bucket }} {{ noggin_url }}


############################################################################
#
#  nix related commands
#
############################################################################

# Update all the flake inputs
[group('nix')]
up:
    nix flake update

# Update specific input

# Usage: just upp nixpkgs
[group('nix')]
upp input:
    nix flake update {{ input }}

# List all generations of the system profile
[group('nix')]
history:
    nix profile history --profile /nix/var/nix/profiles/system

# Open a nix shell with the flake
[group('nix')]
repl:
    nix repl -f flake:nixpkgs

# remove all generations older than 7 days

# on darwin, you may need to switch to root user to run this command
[group('nix')]
clean:
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# Garbage collect all unused nix store entries
[group('nix')]
gc:
    # garbage collect all unused nix store entries(system-wide)
    sudo nix-collect-garbage --delete-older-than 7d
    # garbage collect all unused nix store entries(for the user - home-manager)
    # https://github.com/NixOS/nix/issues/8508
    nix-collect-garbage --delete-older-than 7d

[group('nix')]
fmt:
    # format the nix files in this repo
    nix fmt

# Show all the auto gc roots in the nix store
[group('nix')]
gcroot:
    ls -al /nix/var/nix/gcroots/auto/
