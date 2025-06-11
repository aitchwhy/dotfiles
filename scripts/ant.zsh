#!/usr/bin/env zsh
###############################################################################
# ant.zsh – single-file CLI helper for the Anterior monorepo
#
# Works in three situations out-of-the-box:
#   1. Inside `nix develop` – every `ant-*` binary is already on $PATH.
#   2. Outside a dev-shell but **inside** the repo – falls back to
#      `nix run .#<binary>` (so no global install needed).
#   3. Any other directory – warns politely instead of exploding.
#
# Usage examples:
#   ant pick            # fzf picker for the common ant-* commands
#   ant ports           # show port map
#   ant all-services …  # transparently runs ant-all-services binary
###############################################################################

# -----------------------------------------------------------------------------
# Config – customise if your repo layout is unusual
# -----------------------------------------------------------------------------
# Root of the flake (overridden by $ANT_FLAKE if you like)
readonly _ANT_FLAKE_ROOT=${ANT_FLAKE:-$(git -C "${0:a:h}" rev-parse --show-toplevel 2>/dev/null)}

# All first-class binaries exposed by the flake that start with "ant-"
# (add/remove as the repo evolves – one source of truth for the picker + wrapper)
local -a _ANT_BINARIES=(
  ant-all-services
  ant-system-prune
  ant-check-1password
  ant-build-docker
  ant-build-host
  ant-lint
  ant-sync-cache
  ant-admin
  ant-npm-build-deptree
)

# -----------------------------------------------------------------------------
# Portable wrapper: run binary if on $PATH, else `nix run` from the repo root
# -----------------------------------------------------------------------------
_ant_exec() {
  local bin="$1"; shift
  if command -v "$bin" &>/dev/null; then
    "$bin" "$@"
  elif [[ -d $_ANT_FLAKE_ROOT ]]; then
    # Outside dev-shell – fallback to nix run (makes heavy use of the binary cache)
    nix run "$_ANT_FLAKE_ROOT#$bin" -- "$@"
  else
    print -u2 "✖︎ ant: cannot find $bin and not inside the repo (set \$ANT_FLAKE)"
    return 127
  fi
}

# -----------------------------------------------------------------------------
# fzf picker
# -----------------------------------------------------------------------------
ant_pick() {
  if (( $+commands[fzf] == 0 )); then
    print -u2 "fzf not installed – run \`brew install fzf\` or \`nix profile install nixpkgs#fzf\`"
    return 1
  fi
  local selected=$(
    printf '%s\n' "${_ANT_BINARIES[@]}" |
    fzf --height 40% --reverse --border --prompt='ant ▸ '
  )
  [[ -n $selected ]] && _ant_exec "$selected" "$@"
}

# user-friendly alias that works in every shell
alias antpick='ant_pick'

# -----------------------------------------------------------------------------
# Port helper maps – unchanged except for defensive guards
# -----------------------------------------------------------------------------
typeset -A ANT_PORTS=(
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
  gotenberg               3000
  prefect                 4200
  localstack              4566
  redis                   6379
  postgres                5432
  dynamodb                8000
)

ant_ports_list() {
  for k in ${(k)ANT_PORTS}; do
    print -r -- "${ANT_PORTS[$k]}\t$k"
  done | sort -n
}
alias antports='ant_ports_list'

# -------------------------------------------------------------------
# Killer helpers (slightly hardened; fail gracefully without lsof/fzf)
# -------------------------------------------------------------------
_ant_lsof() {
  command -v lsof &>/dev/null || { print -u2 "lsof missing"; return 1 }
  lsof -Pn -i TCP:$1 -sTCP:LISTEN
}
_ant_kill_port() {
  command -v lsof &>/dev/null || { print -u2 "lsof missing"; return 1 }
  lsof -Pn -ti TCP:$1 | xargs -r kill -9
}

ant_kill() {
  command -v fzf &>/dev/null || { print -u2 "fzf missing"; return 1 }
  local sel=$(ant_ports_list | fzf --prompt='kill ▸ ' --with-nth=1,2)
  [[ -z $sel ]] && return
  _ant_kill_port "${sel%%	*}"
}
alias antkill='ant_kill'

ant_kill_all() {
  print "Killing all processes bound to known Anterior ports…"
  for p in ${(v)ANT_PORTS}; do
    _ant_kill_port $p
  done
}
alias antkillall='ant_kill_all'

# -----------------------------------------------------------------------------
# Main dispatcher – recognised sub-commands come first; otherwise treat the
# first arg as an ant-* binary name and attempt to run it.
# -----------------------------------------------------------------------------
hant() {
  local cmd="$1"; shift

  case "$cmd" in
    ""|-h|--help|help)
      cat <<'EOF'
ant – Anterior monorepo helper

Usage: ant <command> [args...]

Built-in commands:
  pick              Interactive picker for common ant-* binaries
  ports             List canonical service ports
  kill              Interactive killer (uses fzf)
  killall           Kill all processes bound to any ANT_PORTS
  ref               Print reference port table
  env|genenv|s3|dynamo|sqs|service
                    – see project README for details

If <command> matches an ant-* binary name it is executed transparently.
EOF
      ;;

    pick)      ant_pick "$@" ;;
    ports)     ant_ports_list ;;
    kill)      ant_kill ;;
    killall)   ant_kill_all ;;
    ref)       # unchanged banner (truncated for brevity)
               print "API 20101/2/3 …";;
    # -----------------------------------------------------------------
    # fallback: treat <cmd> as a binary (strip optional "ant-" prefix)
    # -----------------------------------------------------------------
    *)
      local bin=$cmd
      [[ $bin == ant-* ]] || bin="ant-$bin"
      _ant_exec "$bin" "$@"
      ;;
  esac
}

# Make the function available when this file is sourced
export ant
