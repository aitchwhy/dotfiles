#!/usr/bin/env zsh
#
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

alias antbuild='ant-npm-build-deptree'

# ant-npm-build-deptree YOUR_TS_PROJECT_NAME (Build dependencies for a TS project)


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
alias antadmin='ant-admin'


# ==========================================================================
# MAIN ANT COMMAND FUNCTION
# ==========================================================================

ant() {
  local command="$1"
  shift

  case "$command" in
    # Port management
    ports)
      echo "Listing all ports in use by Anterior services..."
      lsof -i -P -n | grep LISTEN | grep -E ":(20[0-9]{3}|3000|4[0-9]{3}|6379)" |
        awk '{printf "%-6s %-15s %-8s %-20s %s\n", $2, $1, $9, $10, $0}' |
        sort -k3
      ;;
    kill)
      local subcommand="$1"
      case "$subcommand" in
        port)
          local pid_to_kill
          pid_to_kill=$(ant ports | fzf --header="Select process to kill (Press ESC to cancel)" | awk '{print $1}')
          if [[ -n "$pid_to_kill" ]]; then
            echo "Killing process $pid_to_kill..."
            kill -9 "$pid_to_kill"
            echo "Process killed."
          else
            echo "No process selected."
          fi
          ;;
        all)
          echo "Killing all Anterior service processes..."
          local pids
          pids=$(lsof -i -P -n | grep LISTEN |
            grep -E ":(20[0-9]{3}|3000|4[0-9]{3}|6379)" |
            awk '{print $2}' | sort -u)
          if [[ -n "$pids" ]]; then
            echo "Found processes: $pids"
            echo "$pids" | xargs kill -9
            echo "All processes killed."
          else
            echo "No matching processes found."
          fi
          ;;
        *)
          echo "Usage: ant kill {port|all}"
          ;;
      esac
      ;;
    ref|reference)
      echo "Standard Anterior Service Ports"
      echo "=============================="
      echo "Service                HTTP       Admin      gRPC"
      echo "----------------------------------------------------"
      echo "API                    20101      20102      20103"
      echo "Cortex                 20201      -          -"
      echo "User                   -          -          20303"
      echo "Prior Auth Op          -          -          20403"
      echo "Payment Integrity      -          -          20503"
      echo "Noodle                 20601      -          -"
      echo "Noggin                 20701      -          -"
      echo "Hello World            20901      -          -"
      echo "Clinical Tool Backend  21001      -          -"
      echo "Clinical Tool Frontend 21101      -          -"
      echo ""
      echo "Dependencies"
      echo "============"
      echo "Gotenberg              3000"
      echo "Localstack             4566"
      echo "Prefect                4200"
      echo "Redis                  6379"
      ;;

    # Environment management
    env)
      echo "Anterior Environment Variables:"
      env | grep -E "^(ANT_|AWS_|PREFECT_|DD_|NEXT_)" | sort
      ;;
    genenv)
      local target_file="${1:-.env}"
      if [[ -f "$target_file" ]]; then
        read -p "File $target_file already exists. Overwrite? (y/N) " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
          echo "Aborted."
          return 1
        fi
      fi
      echo "Generating $target_file with default environment variables..."
      cat > "$target_file" << 'EOF'
# Common variables
ANT_S3_BUCKET=local-bucket
ANT_JWT_SECRET=delightfullyIntense
ANT_ALLOWED_ORIGINS=http://localhost:20201
ANT_JOB_SQS=http://localhost:4566/000000000000/prefect-queue
ANT_LOG_FORMAT=plaintext
PREFECT_API_URL=http://localhost:4200/api

# LocalStack Configuration
AWS_ACCESS_KEY_ID=000000000000
AWS_SECRET_ACCESS_KEY=local-stack-accepts-anything-here
AWS_ENDPOINT_URL=http://localhost:4566
AWS_REGION=us-east-1
AWS_DEFAULT_REGION=us-east-1
SQS_ENDPOINT_URL=http://localhost:4566

# DynamoDB Tables
ANT_EVENTS_TABLE_NAME=events
ANT_EVENTS_TABLE_NAME_COMING_SOON_202505=events-coming-soon-202505
ANT_EVENTS_SCHEMA_VERSION=v1

# Brrr Configuration
ANT_BRRR_DYNAMO_TABLE=brrr
ANT_BRRR_REDIS_URL=redis://localhost:6379
EOF
      echo "Environment file created at $target_file"
      ;;

    # AWS S3 management
    s3)
      local subcommand="$1"
      shift
      case "$subcommand" in
        buckets|ls-buckets)
          echo "Listing S3 buckets in LocalStack..."
          AWS_ENDPOINT_URL=http://localhost:4566 aws s3 ls
          ;;
        ls)
          local bucket="${1:-local-bucket}"
          echo "Listing objects in bucket $bucket..."
          AWS_ENDPOINT_URL=http://localhost:4566 aws s3 ls "s3://$bucket/" --recursive
          ;;
        cat)
          local path="$1"
          if [[ -z "$path" ]]; then
            echo "Usage: ant s3 cat <s3-path>"
            echo "Example: ant s3 cat s3://local-bucket/workspaces/123/category/source/artifact.json"
            return 1
          fi
          echo "Displaying contents of $path..."
          AWS_ENDPOINT_URL=http://localhost:4566 aws s3 cp "$path" -
          ;;
        *)
          echo "Usage: ant s3 {buckets|ls [bucket]|cat <path>}"
          ;;
      esac
      ;;

    # DynamoDB management
    dynamo)
      local subcommand="$1"
      shift
      case "$subcommand" in
        tables)
          echo "Listing DynamoDB tables in LocalStack..."
          AWS_ENDPOINT_URL=http://localhost:4566 aws dynamodb list-tables
          ;;
        scan)
          local table="$1"
          if [[ -z "$table" ]]; then
            echo "Usage: ant dynamo scan <table-name>"
            echo "Example: ant dynamo scan events"
            return 1
          fi
          echo "Scanning DynamoDB table $table..."
          AWS_ENDPOINT_URL=http://localhost:4566 aws dynamodb scan --table-name "$table" | jq
          ;;
        *)
          echo "Usage: ant dynamo {tables|scan <table>}"
          ;;
      esac
      ;;

    # SQS management
    sqs)
      local subcommand="$1"
      shift
      case "$subcommand" in
        queues)
          echo "Listing SQS queues in LocalStack..."
          AWS_ENDPOINT_URL=http://localhost:4566 aws sqs list-queues
          ;;
        receive)
          local queue_url="$1"
          if [[ -z "$queue_url" ]]; then
            echo "Usage: ant sqs receive <queue-url>"
            echo "Example: ant sqs receive http://localhost:4566/000000000000/prefect-queue"
            return 1
          fi
          echo "Receiving messages from queue $queue_url..."
          AWS_ENDPOINT_URL=http://localhost:4566 aws sqs receive-message --queue-url "$queue_url" --max-number-of-messages 10 | jq
          ;;
        send)
          local queue_url="$1"
          local message="$2"
          if [[ -z "$queue_url" || -z "$message" ]]; then
            echo "Usage: ant sqs send <queue-url> <message>"
            echo "Example: ant sqs send http://localhost:4566/000000000000/prefect-queue '{\"key\":\"value\"}'"
            return 1
          fi
          echo "Sending message to queue $queue_url..."
          AWS_ENDPOINT_URL=http://localhost:4566 aws sqs send-message --queue-url "$queue_url" --message-body "$message"
          ;;
        *)
          echo "Usage: ant sqs {queues|receive <url>|send <url> <message>}"
          ;;
      esac
      ;;

    # Service management
    svc|service)
      local subcommand="$1"
      shift
      case "$subcommand" in
        status)
          local service="${1:-data-seeder}"
          echo "Checking $service status..."
          nix run .#ant-all-services -- status "$service"
          ;;
        start)
          local service="${1:-data-seeder}"
          echo "Starting $service..."
          nix run .#ant-all-services -- start "$service"
          ;;
        logs)
          local service="${1:-data-seeder}"
          echo "Viewing $service logs..."
          nix run .#ant-all-services -- logs "$service"
          ;;
        *)
          echo "Usage: ant service {status|start|logs} [service-name]"
          ;;
      esac
      ;;

    # Help
    help|--help|-h|"")
      echo "Anterior Dev Utils"
      echo "=================="
      echo
      echo "Usage: ant <command> [subcommand] [args...]"
      echo
      echo "COMMANDS:"
      echo "  ports                  - List all ports in use by Anterior services"
      echo "  kill {port|all}        - Kill processes (interactive port selection or all)"
      echo "  ref|reference          - Show standard port assignments"
      echo
      echo "  env                    - View all Anterior environment variables"
      echo "  genenv [file]          - Generate a default .env file"
      echo
      echo "  s3 {buckets|ls|cat}    - S3 operations (buckets, list objects, view object)"
      echo "  dynamo {tables|scan}   - DynamoDB operations"
      echo "  sqs {queues|receive|send} - SQS operations"
      echo
      echo "  service {status|start|logs} [name] - Service management (default: data-seeder)"
      echo
      echo "EXAMPLES:"
      echo "  ant ports              - List all service ports"
      echo "  ant kill port          - Interactive port killer"
      echo "  ant kill all           - Kill all services"
      echo "  ant s3 ls mybucket     - List objects in S3 bucket"
      echo "  ant dynamo scan events - Scan DynamoDB events table"
      echo "  ant service logs       - View data-seeder logs"
      ;;

    *)
      echo "Unknown command: $command"
      echo "Run 'ant help' for usage information."
      return 1
      ;;
  esac
}
