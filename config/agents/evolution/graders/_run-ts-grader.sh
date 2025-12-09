#!/usr/bin/env bash
# Shim to run TypeScript grader and output JSON
# Usage: _run-ts-grader.sh <grader-name>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRADER_NAME="${1:-}"

if [[ -z "$GRADER_NAME" ]]; then
    echo '{"grader":"unknown","score":0,"passed":false,"issues":["no grader name provided"]}'
    exit 1
fi

cd "$SCRIPT_DIR/.."
bun run src/graders/cli.ts "$GRADER_NAME" 2>/dev/null || {
    echo "{\"grader\":\"$GRADER_NAME\",\"score\":0,\"passed\":false,\"issues\":[\"grader execution error\"]}"
    exit 1
}
