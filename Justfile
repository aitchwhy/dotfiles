# just is a command runner, Justfile is very similar to Makefile, but simpler.

# TODO update hostname here!
hostname := "your-hostname"

# Flonotes Frontend variables and settings

# List all the just commands
default:
  @just --list

############################################################################
#
#  Darwin related commands
#
############################################################################

#  TODO Feel free to remove this target if you don't need a proxy to speed up the build process
[group('desktop')]
darwin-set-proxy:
  sudo python3 scripts/darwin_set_proxy.py

[group('desktop')]
darwin: darwin-set-proxy
  nix build .#darwinConfigurations.{{hostname}}.system \
    --extra-experimental-features 'nix-command flakes'

  ./result/sw/bin/darwin-rebuild switch --flake .#{{hostname}}

[group('desktop')]
darwin-debug: darwin-set-proxy
  nix build .#darwinConfigurations.{{hostname}}.system --show-trace --verbose \
    --extra-experimental-features 'nix-command flakes'

  ./result/sw/bin/darwin-rebuild switch --flake .#{{hostname}} --show-trace --verbose

############################################################################
#
#  nix related commands
#
############################################################################

############################################################################
#
# Flonotes Frontend commands
#
############################################################################

# Path variables for Flonotes development
flonotes_platform := "~/src/platform"
flonotes_fe := "~/src/flonotes-fe"

[group('flonotes')]
run-noggin: deploy-local
    cd {{flonotes_platform}} && \
      ant build noggin && \
      ant up noggin

[group('flonotes')]
run-platform:
    cd {{flonotes_platform}} && \
      ant build api user s3 prefect-worker prefect-agent prefect-server data-seeder && \
      ant up api user s3 prefect-worker prefect-agent prefect-server data-seeder

# Run the development server with hot reloading
[group('flonotes')]
run:
    cd {{flonotes_fe}} && npm run dev --hot

# Get OTP codes from Docker logs (outputs only the 4-digit code)
[group('flonotes')]
get-otp:
    docker logs "$(docker container ls | rg 'api' | awk '{print $1}')" | rg "sent an otp code"

# Setup project
[group('flonotes')]
setup:
    cd {{flonotes_fe}} && npm install && npm run build

# Deploy to local environment
[group('flonotes')]
deploy-local:
    cd {{flonotes_fe}} && \
    $(pwd)/{{justfile_directory()}}/scripts/anterior/deploy-local.sh http://localhost:59000

# Deploy to AWS
[group('flonotes')]
deploy-aws profile bucket noggin_url:
    cd {{flonotes_fe}} && \
    $(pwd)/{{justfile_directory()}}/scripts/anterior/deploy-aws.sh {{ profile }} {{ bucket }} {{ noggin_url }}

# Update all the flake inputs
[group('nix')]
up:
  nix flake update

# Update specific input
# Usage: just upp nixpkgs
[group('nix')]
upp input:
  nix flake update {{input}}

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
