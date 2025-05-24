#!/bin/bash

# Array of commands prefixed with "ant-"
ant_commands=(
  "ant-all-services"
  "ant-system-prune"
  "ant-check-1password"
  "ant-build-docker"
  "ant-build-host"
  "ant-lint"
  "ant-sync-cache"
  "ant-admin"
)
#
# # anterior
# alias antall="ant-all-services"
# alias aprune="ant-system-prune"
#
# alias antnpmci="npm ci --ignore-scripts"
# alias antnpmbuild="ant-npm-build-deptree SERVICE_NAME"
# alias antnpmrun="npm run --workspace your/dir build"

# Use fzf to select a command and store it in a variable
selected_command=$(printf "%s\n" "${ant_commands[@]}" | fzf --height 40% --reverse --border --prompt="Select a command: ")

# If a command was selected (fzf wasn't cancelled), run it
if [[ -n "$selected_command" ]]; then
  echo "Running: $selected_command"
  eval "$selected_command"
else
  echo "No command selected."
fi


# Quick utilities for viewing and managing the local ports used by the
# Anterior process-compose stack defined in nix/anterior-services-process-compose.nix.
#
#   source scripts/ant-ports.zsh
#
# Provides:
#   ANT_PORTS             – associative array mapping <name> -> <port>
#   ant_ports_list        – list mapping sorted by port
#   ant_ports_fzf         – fuzzy finder (needs fzf) – enter to inspect, ^X to kill
#
# The array is hand-derived from the same arithmetic used in the nix module so we
# keep only one source of truth for humans.  Update it when the module changes.

# ---------------------------------------------------------------------------
# Port map
# ---------------------------------------------------------------------------
# NOTE: Only *listener* ports are included; helper processes without their own
# bound port (prefect-agent, prefect-worker, …) are not listed.

typeset -A ANT_PORTS=(
	# core services
	api_http                20101
	api_admin               20102
	api_grpc                20103
	cortex_http             20201
	user_grpc               20303
	paop_grpc               20403
	payment_integrity_grpc  20503
	noodle_http             20601
	noggin_http             20701
	hello_world_http        20901
	clinical_backend_http   21101
	clinical_frontend_http  21201
	# third-party / dependencies
	gotenberg               3000
	prefect                 4200
	localstack              4566
	redis                   6379
	postgres                5432
	dynamodb                8000
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# List <port> <name>, sorted by port number (ascending)
function ant_ports_list() {
	for k v in "${(@kv)ANT_PORTS}"; do
		print -r -- "$v\t$k"
	done | sort -n
}

# Show the processes currently bound to a port.
function _ant_port_lsof() {
	local port=$1
	if (( $+commands[lsof] == 0 )); then
		echo "lsof not found" >&2
		return 1
	fi
	lsof -Pn -i TCP:${port} -sTCP:LISTEN
}

# Kill processes bound to a specific port
function _ant_port_kill() {
	local port=$1
	if (( $+commands[lsof] == 0 )); then
		echo "lsof not found" >&2
		return 1
	fi
	lsof -Pn -ti TCP:${port} | xargs -r kill -9
	echo "Killed processes on port $port"
}

# Fuzzy select a port and kill processes bound to it
function ant_kill() {
	if (( $+commands[fzf] == 0 )); then
		echo "fzf not found – install fzf first" >&2
		return 1
	fi

	local selected=$(ant_ports_list | fzf --prompt="Select port to kill> " --with-nth=1,2 --header=$'PORT\tNAME')
	if [[ -n "$selected" ]]; then
		local port=$(echo "$selected" | awk '{print $1}')
		_ant_port_kill "$port"
	fi
}

# Kill *all* processes bound to known ANT_PORTS (use with caution)
function ant_kill_all() {
	echo "Killing all Anterior service ports..."
	for port in ${(v)ANT_PORTS}; do
		_ant_port_kill "$port"
	done
	echo "✅ All known Anterior ports cleared"
}

# Simple function to list all ports
function ant_ports() {
	ant_ports_list
}

# ---------------------------------------------------------------------------
# Aliases for faster typing
# ---------------------------------------------------------------------------

alias antports='ant_ports_list'
alias antkill='ant_kill'
alias antkillall='ant_kill_all'
# Convenience: list and immediately show lsof on every port in the map
function ant_ports_lsof_all() {
	for p in ${(v)ANT_PORTS}; do
		echo "=== Port $p ==="
		_ant_port_lsof $p || true
		echo
	done
}


# Commands to Run in Your Normal ZSH Shell
#
# Nix Environment Management:
#
# nix run .#ant -- ant-setup-nix-cache (Set up cache credentials)
# darwin-rebuild switch --flake .#anterior-base (Configure macOS environment)
# nix develop .#npm (Enter the NPM development shell)
# nix run .#ant -- ant-build-docker (Build Docker images)
# nix run .#ant -- ant-all-services (Run all services)
# nix flake check (Run tests)
#
#
# One-off Tool Execution:
#
# nix run .#ruff -- check (Run ruff linter)
# nix run .#admin -- <command> (Run the admin tool)
# nix shell .#nodejs (Get a shell with just Node.js)
#
#
# Development Environment Entry:
#
# nix develop (Enter default dev shell)
# nix develop .#npm (Enter NPM-specific dev shell)
#
#
#
# Commands to Run Inside Nix Develop Shell
# Once you're inside the Nix develop shell (after running nix develop .#npm), you would run:
#
# NPM Commands:
#
# npm ci --ignore-scripts (Install dependencies)
# npm run --workspace your/dir build (Build a specific project)
# npm run --workspace your/dir start (Start a specific project)
#
#
# Helper Tools (available within the shell):
#
# ant-npm-build-deptree YOUR_TS_PROJECT_NAME (Build dependencies for a TS project)

antbuild='ant-npm-build-deptree'

ant-npm-build-deptree YOUR_TS_PROJECT_NAME (Build dependencies for a TS project)


#
#
# Dev Shell Commands (available in the default dev shell):
#
# ant-check-1password (Verify 1Password integration)
alias ant1p='ant-check-1password'

# ant-lint (Lint code in current directory)
alias antlint='ant-lint'

# system-prune (Clean up Nix/Docker resources)
alias antclean='system-prune'

# ant-admin (Run Anterior admin tool)
antadmin='ant-admin'

