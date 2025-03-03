#!/usr/bin/env zsh

# ========================================================================
# ZSH Functions - Core utility functions organized by category
# ========================================================================

# ========================================================================
# Logging Functions
# ========================================================================
function log_info() {
  printf '%s[INFO]%s %s\n' "${BLUE:-}" "${RESET:-}" "$*"
}

function log_success() {
  printf '%s[SUCCESS]%s %s\n' "${GREEN:-}" "${RESET:-}" "$*"
}

function log_warning() {
  printf '%s[WARNING]%s %s\n' "${YELLOW:-}" "${RESET:-}" "$*" >&2
}

function log_error() {
  printf '%s[ERROR]%s %s\n' "${RED:-}" "${RESET:-}" "$*" >&2
}

# Progress indicator
function show_progress() {
  printf '%s→%s %s...\n' "${BLUE:-}" "${RESET:-}" "$*"
}

# ========================================================================
# Environment Settings
# ========================================================================

# source $ZDOTDIR/.zprofile
# export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# export ZDOTDIR=${ZDOTDIR:-$HOME/.config/zsh}

# Search environment variables with grep (built-in)
function penvgrep() {
  echo "======== env vars =========="
  if [ -z "$1" ]; then
    printenv | sort | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
  else
    printenv | sort | grep -i "$1" | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
  fi
  echo "============================"
}

# ========================================================================
# System & macOS Utilities
# ========================================================================

# Toggle macOS hidden files
function togglehidden() {
  local current
  current=$(defaults read com.apple.finder AppleShowAllFiles)
  defaults write com.apple.finder AppleShowAllFiles $((!current))
  killall Finder
  log_success "Finder hidden files: $((!current))"
}

# Quick Look from terminal
function ql() {
  qlmanage -p "$@" &>/dev/null
}

# Weather information with optional location
function weather() {
  local city="${1:-}"
  curl -s "wttr.in/$city?format=v2"
}

# Kill process running on a specified port
function killport() {
  local port="$1"
  if [[ -z "$port" ]]; then
    log_error "Please specify a port number"
    return 1
  fi

  local pid
  pid=$(lsof -i ":$port" | awk 'NR!=1 {print $2}')

  if [[ -z "$pid" ]]; then
    log_error "No process found on port $port"
    return 1
  fi

  echo "Killing process(es) on port $port: $pid"
  echo "$pid" | xargs kill -9
  log_success "Process(es) killed"
}

# Show top 10 largest files in current directory
function ducks() {
  du -sh * | sort -rh | head -10
}

# Improved man pages with bat
function batman() {
  MANPAGER="sh -c 'col -bx | bat -l man -p'" man "$@"
}

# ========================================================================
# Yazi File Manager Configuration
# ========================================================================
function y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" ]] && [[ "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd" || return 1
  fi
  rm -f -- "$tmp"
}

# ========================================================================
# Homebrew Bundle Management
# ========================================================================
function bb() {
  case "$1" in
  save)
    brew bundle dump --force --describe --global
    ;;
  install)
    brew bundle install --global --all
    ;;
  check)
    brew bundle check --global --verbose --all
    ;;
  unlisted)
    brew bundle cleanup --global --verbose --all --zap
    ;;
  clean)
    brew bundle cleanup --global --verbose --all --zap -f
    ;;
  edit)
    brew bundle edit --global
    ;;
  *)
    echo "Usage: bb [save|install|check|unlisted|clean|edit]"
    ;;
  esac
}

###############################################################################
#                   macOS Application Management Utilities                    #
#                                                                             #
# A comprehensive set of utilities for discovering, comparing, and managing   #
# applications installed via various methods on macOS.                        #
###############################################################################

# Base directory for output
APP_AUDIT_DIR="${HOME}/.app_audit"

###############################################################################
#                           Core Utility Functions                            #
###############################################################################

# General collection function that all specific collectors will use
function _collect_data() {
  local source_type="$1"
  local output_file="$2"
  local collection_cmd="$3"
  local count_cmd="${4:-wc -l}"

  mkdir -p "$(dirname "$output_file")"

  eval "$collection_cmd" > "$output_file"

  local count
  if [[ "$count_cmd" == "wc -l" ]]; then
    count=$(wc -l < "$output_file")
  else
    count=$(eval "$count_cmd" < "$output_file")
  fi

  echo "Collected $count $source_type to $output_file"
}

# Extraction utility function
function _extract_app_names() {
  local source_type="$1"
  local input_file="$2"
  local output_file="$3"
  local extract_cmd="$4"

  mkdir -p "$(dirname "$output_file")"

  eval "$extract_cmd" > "$output_file"

  echo "Extracted $(wc -l < "$output_file") app names from $input_file to $output_file"
}

###############################################################################
#                         Homebrew Collection Functions                       #
###############################################################################

function collect_homebrew_formulae() {
  local output_file="${1:-${APP_AUDIT_DIR}/homebrew_formulae.txt}"
  _collect_data "Homebrew formulae" "$output_file" "brew list --formula"
}

function collect_homebrew_casks() {
  local output_file="${1:-${APP_AUDIT_DIR}/homebrew_casks.txt}"
  _collect_data "Homebrew casks" "$output_file" "brew list --cask"
}

function extract_homebrew_cask_names() {
  local input_file="$1"
  local output_file="$2"
  _extract_app_names "Homebrew cask names" "$input_file" "$output_file" \
    "cut -d ' ' -f 1 \"$input_file\" | sort"
}

###############################################################################
#                     Mac App Store Collection Functions                      #
###############################################################################

function collect_mas_apps() {
  local output_file="${1:-${APP_AUDIT_DIR}/mas_apps.txt}"
  _collect_data "Mac App Store apps" "$output_file" "mas list"
}

function extract_mas_app_names() {
  local input_file="$1"
  local output_file="$2"
  _extract_app_names "Mac App Store app names" "$input_file" "$output_file" \
    "awk '{\\$1=\"\"; print \\$0}' \"$input_file\" | sed 's/^ //g' | sort"
}

###############################################################################
#                     GUI Applications Collection Functions                   #
###############################################################################

function collect_global_gui_apps() {
  local output_file="${1:-${APP_AUDIT_DIR}/global_apps.txt}"
  _collect_data "global applications" "$output_file" "find /Applications -name \"*.app\" | sort"
}

function collect_user_gui_apps() {
  local output_file="${1:-${APP_AUDIT_DIR}/user_apps.txt}"
  _collect_data "user applications" "$output_file" "find ~/Applications -name \"*.app\" 2>/dev/null | sort"
}

function collect_system_gui_apps() {
  local output_file="${1:-${APP_AUDIT_DIR}/system_apps.txt}"
  _collect_data "system applications" "$output_file" "find /System/Applications -name \"*.app\" | sort"
}

function extract_gui_app_names() {
  local input_file="$1"
  local output_file="$2"
  _extract_app_names "GUI app names" "$input_file" "$output_file" \
    "cat \"$input_file\" | xargs -I{} basename {} .app | sort"
}

###############################################################################
#                     Package Installer Collection Functions                  #
###############################################################################

function collect_pkg_receipts() {
  local output_file="${1:-${APP_AUDIT_DIR}/pkg_receipts.txt}"
  _collect_data "package receipts" "$output_file" "ls -1 /var/db/receipts/ | grep \".bom\|.plist\""
}

function collect_install_history() {
  local output_file="${1:-${APP_AUDIT_DIR}/install_history.xml}"
  mkdir -p "$(dirname "$output_file")"
  plutil -convert xml1 -o "$output_file" /Library/Receipts/InstallHistory.plist
  echo "Collected install history to $output_file"
}

###############################################################################
#                         Launch Services Functions                           #
###############################################################################

function collect_launch_service() {
  local service_type="$1"
  local path="$2"
  local output_file="$3"
  local sudo_prefix="${4:-}"

  _collect_data "$service_type" "$output_file" "${sudo_prefix}ls -la $path 2>/dev/null"
}

function collect_user_launch_agents() {
  local output_file="${1:-${APP_AUDIT_DIR}/user_launch_agents.txt}"
  collect_launch_service "user launch agents" "~/Library/LaunchAgents/" "$output_file"
}

function collect_global_launch_agents() {
  local output_file="${1:-${APP_AUDIT_DIR}/global_launch_agents.txt}"
  collect_launch_service "global launch agents" "/Library/LaunchAgents/" "$output_file" "sudo "
}

function collect_system_launch_agents() {
  local output_file="${1:-${APP_AUDIT_DIR}/system_launch_agents.txt}"
  collect_launch_service "system launch agents" "/System/Library/LaunchAgents/" "$output_file"
}

function collect_global_launch_daemons() {
  local output_file="${1:-${APP_AUDIT_DIR}/global_launch_daemons.txt}"
  collect_launch_service "global launch daemons" "/Library/LaunchDaemons/" "$output_file" "sudo "
}

function collect_system_launch_daemons() {
  local output_file="${1:-${APP_AUDIT_DIR}/system_launch_daemons.txt}"
  collect_launch_service "system launch daemons" "/System/Library/LaunchDaemons/" "$output_file"
}

function collect_disabled_services() {
  local output_file="${1:-${APP_AUDIT_DIR}/disabled_services.txt}"
  mkdir -p "$(dirname "$output_file")"

  echo "=== DISABLED LAUNCH AGENTS/DAEMONS ===" > "$output_file"
  sudo launchctl print-disabled system | grep true >> "$output_file"
  launchctl print-disabled gui/$(id -u) | grep true >> "$output_file"

  echo "Collected disabled launch services to $output_file"
}

###############################################################################
#                          Multi-user Functions                               #
###############################################################################

function collect_all_users_apps() {
  local output_dir="${1:-${APP_AUDIT_DIR}/users}"
  mkdir -p "$output_dir"

  # Get all user homes
  sudo dscl . -list /Users HomeDirectory | grep -v "^_" | awk '{print $2}' > "$output_dir/user_homes.txt"

  # For each user, find their applications
  while read home; do
    user=$(basename "$home")
    echo "Checking user: $user"

    # Only process if home directory exists
    if [ -d "$home" ]; then
      find "$home/Applications" -name "*.app" 2>/dev/null |
        sort > "$output_dir/${user}_apps.txt"

      # User-specific launch agents
      find "$home/Library/LaunchAgents" -type f -name "*.plist" 2>/dev/null |
        sort > "$output_dir/${user}_launch_agents.txt"

      echo "Collected $(wc -l < "$output_dir/${user}_apps.txt") applications for user $user"
    fi
  done < "$output_dir/user_homes.txt"

  echo "Collected applications for all users to $output_dir"
}

###############################################################################
#                           Analysis Functions                                #
###############################################################################

function find_duplicates_between() {
  local source1_name="$1"
  local source1_file="$2"
  local source2_name="$3"
  local source2_file="$4"
  local output_file="$5"

  mkdir -p "$(dirname "$output_file")"

  echo "=== DUPLICATES: $source1_name vs $source2_name ===" > "$output_file"
  comm -12 "$source1_file" "$source2_file" | while read app; do
    echo "App '$app' found in both $source1_name and $source2_name" >> "$output_file"
  done

  local count=$(grep -c "App" "$output_file" || echo 0)
  echo "Found $count duplicates between $source1_name and $source2_name"
}

function generate_report() {
  local input_dir="$1"
  local output_file="$2"

  mkdir -p "$(dirname "$output_file")"

  {
    echo "=== APPLICATION AUDIT REPORT ==="
    echo "Generated: $(date)"
    echo

    echo "=== INSTALLATION SUMMARY ==="
    [ -f "$input_dir/homebrew_formulae.txt" ] && echo "Homebrew Formulae: $(wc -l < "$input_dir/homebrew_formulae.txt")"
    [ -f "$input_dir/homebrew_casks.txt" ] && echo "Homebrew Casks: $(wc -l < "$input_dir/homebrew_casks.txt")"
    [ -f "$input_dir/mas_apps.txt" ] && echo "Mac App Store Apps: $(wc -l < "$input_dir/mas_apps.txt")"
    [ -f "$input_dir/system_apps.txt" ] && echo "System Applications: $(wc -l < "$input_dir/system_apps.txt")"
    [ -f "$input_dir/global_apps.txt" ] && echo "Global Applications: $(wc -l < "$input_dir/global_apps.txt")"
    [ -f "$input_dir/user_apps.txt" ] && echo "User Applications: $(wc -l < "$input_dir/user_apps.txt")"
    echo

    echo "=== LAUNCH SERVICES SUMMARY ==="
    [ -f "$input_dir/user_launch_agents.txt" ] && echo "User Launch Agents: $(grep -c "\.plist" "$input_dir/user_launch_agents.txt" || echo 0)"
    [ -f "$input_dir/global_launch_agents.txt" ] && echo "Global Launch Agents: $(grep -c "\.plist" "$input_dir/global_launch_agents.txt" || echo 0)"
    [ -f "$input_dir/system_launch_agents.txt" ] && echo "System Launch Agents: $(grep -c "\.plist" "$input_dir/system_launch_agents.txt" || echo 0)"
    [ -f "$input_dir/global_launch_daemons.txt" ] && echo "Global Launch Daemons: $(grep -c "\.plist" "$input_dir/global_launch_daemons.txt" || echo 0)"
    [ -f "$input_dir/system_launch_daemons.txt" ] && echo "System Launch Daemons: $(grep -c "\.plist" "$input_dir/system_launch_daemons.txt" || echo 0)"
    echo

    # Include duplicates data if available
    if [ -d "$input_dir/duplicates" ]; then
      echo "=== DUPLICATES SUMMARY ==="
      find "$input_dir/duplicates" -type f | while read dup_file; do
        echo "$(basename "$dup_file" .txt):"
        grep "App" "$dup_file" | head -5
        local count=$(grep -c "App" "$dup_file" || echo 0)
        if [ "$count" -gt 5 ]; then
          echo "... and $(($count - 5)) more duplicates. See $dup_file for complete list."
        fi
        echo
      done
    fi
  } > "$output_file"

  echo "Generated report at $output_file"
}

###############################################################################
#                          Unified CLI Interface                              #
###############################################################################

function macapps() {
  # Define default values
  local cmd_action=""
  local sources=()
  local output_dir="${APP_AUDIT_DIR}/$(date +%Y%m%d_%H%M%S)"
  local run_analysis=false

  # Parse command arguments
  if [ $# -eq 0 ]; then
    _macapps_help
    return 1
  fi

  cmd_action="$1"
  shift

  case "$cmd_action" in
    "collect")
      # Handle collect subcommand
      while [ $# -gt 0 ]; do
        case "$1" in
          --all)
            sources=(homebrew-formulae homebrew-casks mas global-apps user-apps system-apps pkg-receipts install-history)
            shift
            ;;
          --brew)
            sources+=(homebrew-formulae homebrew-casks)
            shift
            ;;
          --mas)
            sources+=(mas)
            shift
            ;;
          --gui)
            sources+=(global-apps user-apps system-apps)
            shift
            ;;
          --pkg)
            sources+=(pkg-receipts install-history)
            shift
            ;;
          --output)
            output_dir="$2"
            shift 2
            ;;
          --analyze)
            run_analysis=true
            shift
            ;;
          *)
            sources+=("$1")
            shift
            ;;
        esac
      done

      # If no sources specified, use all
      if [ ${#sources[@]} -eq 0 ]; then
        sources=(homebrew-formulae homebrew-casks mas global-apps user-apps system-apps pkg-receipts install-history)
      fi

      mkdir -p "$output_dir"

      # Collect data for each source
      for source in "${sources[@]}"; do
        case "$source" in
          homebrew-formulae)
            collect_homebrew_formulae "$output_dir/homebrew_formulae.txt"
            ;;
          homebrew-casks)
            collect_homebrew_casks "$output_dir/homebrew_casks.txt"
            ;;
          mas)
            collect_mas_apps "$output_dir/mas_apps.txt"
            ;;
          global-apps)
            collect_global_gui_apps "$output_dir/global_apps.txt"
            ;;
          user-apps)
            collect_user_gui_apps "$output_dir/user_apps.txt"
            ;;
          system-apps)
            collect_system_gui_apps "$output_dir/system_apps.txt"
            ;;
          pkg-receipts)
            collect_pkg_receipts "$output_dir/pkg_receipts.txt"
            ;;
          install-history)
            collect_install_history "$output_dir/install_history.xml"
            ;;
          all-users)
            collect_all_users_apps "$output_dir/users"
            ;;
          *)
            echo "Unknown source: $source"
            ;;
        esac
      done

      # Run analysis if requested
      if [ "$run_analysis" = true ]; then
        macosapps analyze --input "$output_dir" --output "$output_dir"
      fi
      ;;

    "launch-services")
      # Handle launch-services subcommand
      local services=()

      while [ $# -gt 0 ]; do
        case "$1" in
          --all)
            services=(user-agents global-agents system-agents global-daemons system-daemons disabled)
            shift
            ;;
          --user)
            services+=(user-agents)
            shift
            ;;
          --global)
            services+=(global-agents global-daemons)
            shift
            ;;
          --system)
            services+=(system-agents system-daemons)
            shift
            ;;
          --output)
            output_dir="$2"
            shift 2
            ;;
          *)
            services+=("$1")
            shift
            ;;
        esac
      done

      # If no services specified, use all
      if [ ${#services[@]} -eq 0 ]; then
        services=(user-agents global-agents system-agents global-daemons system-daemons disabled)
      fi

      mkdir -p "$output_dir"

      # Collect data for each service
      for service in "${services[@]}"; do
        case "$service" in
          user-agents)
            collect_user_launch_agents "$output_dir/user_launch_agents.txt"
            ;;
          global-agents)
            collect_global_launch_agents "$output_dir/global_launch_agents.txt"
            ;;
          system-agents)
            collect_system_launch_agents "$output_dir/system_launch_agents.txt"
            ;;
          global-daemons)
            collect_global_launch_daemons "$output_dir/global_launch_daemons.txt"
            ;;
          system-daemons)
            collect_system_launch_daemons "$output_dir/system_launch_daemons.txt"
            ;;
          disabled)
            collect_disabled_services "$output_dir/disabled_services.txt"
            ;;
          *)
            echo "Unknown service: $service"
            ;;
        esac
      done
      ;;

    "analyze")
      # Handle analyze subcommand
      local input_dir=""

      while [ $# -gt 0 ]; do
        case "$1" in
          --input)
            input_dir="$2"
            shift 2
            ;;
          --output)
            output_dir="$2"
            shift 2
            ;;
          *)
            echo "Unknown option: $1"
            shift
            ;;
        esac
      done

      if [ -z "$input_dir" ]; then
        echo "Error: --input directory must be specified"
        return 1
      fi

      mkdir -p "$output_dir/duplicates"
      mkdir -p "$output_dir/extracted"

      # Extract app names for comparison
      if [ -f "$input_dir/homebrew_casks.txt" ]; then
        extract_homebrew_cask_names "$input_dir/homebrew_casks.txt" "$output_dir/extracted/homebrew_casks_names.txt"
      fi

      if [ -f "$input_dir/mas_apps.txt" ]; then
        extract_mas_app_names "$input_dir/mas_apps.txt" "$output_dir/extracted/mas_names.txt"
      fi

      if [ -f "$input_dir/global_apps.txt" ]; then
        extract_gui_app_names "$input_dir/global_apps.txt" "$output_dir/extracted/global_apps_names.txt"
      fi

      if [ -f "$input_dir/user_apps.txt" ]; then
        extract_gui_app_names "$input_dir/user_apps.txt" "$output_dir/extracted/user_apps_names.txt"
      fi

      # Find duplicates between different sources
      if [ -f "$output_dir/extracted/homebrew_casks_names.txt" ] && [ -f "$output_dir/extracted/global_apps_names.txt" ]; then
        find_duplicates_between "Homebrew Casks" "$output_dir/extracted/homebrew_casks_names.txt" \
                               "Global Apps" "$output_dir/extracted/global_apps_names.txt" \
                               "$output_dir/duplicates/brew_vs_global.txt"
      fi

      if [ -f "$output_dir/extracted/mas_names.txt" ] && [ -f "$output_dir/extracted/global_apps_names.txt" ]; then
        find_duplicates_between "Mac App Store" "$output_dir/extracted/mas_names.txt" \
                               "Global Apps" "$output_dir/extracted/global_apps_names.txt" \
                               "$output_dir/duplicates/mas_vs_global.txt"
      fi

      if [ -f "$output_dir/extracted/homebrew_casks_names.txt" ] && [ -f "$output_dir/extracted/mas_names.txt" ]; then
        find_duplicates_between "Homebrew Casks" "$output_dir/extracted/homebrew_casks_names.txt" \
                               "Mac App Store" "$output_dir/extracted/mas_names.txt" \
                               "$output_dir/duplicates/brew_vs_mas.txt"
      fi

      # Generate report
      generate_report "$output_dir" "$output_dir/report.txt"

      echo "Analysis complete. Report saved to $output_dir/report.txt"
      ;;

    "help"|*)
      _macosapps_help
      ;;
  esac
}

function _macapps_help() {
  echo "macOS Application Management Utility"
  echo
  echo "Usage:"
  echo "  macosapps collect [sources] [options]  - Collect app installation data"
  echo "  macosapps launch-services [types] [options] - Collect launch services data"
  echo "  macosapps analyze [options]            - Analyze for duplicates"
  echo "  macosapps help                        - Show this help"
  echo
  echo "Collection Sources:"
  echo "  --all                  - All installation sources"
  echo "  --brew                 - Homebrew formulae and casks"
  echo "  --mas                  - Mac App Store apps"
  echo "  --gui                  - GUI applications (/Applications, ~/Applications, /System/Applications)"
  echo "  --pkg                  - Package installer receipts"
  echo "  homebrew-formulae      - Homebrew formulae only"
  echo "  homebrew-casks         - Homebrew casks only"
  echo "  mas                    - Mac App Store apps only"
  echo "  global-apps            - Applications in /Applications"
  echo "  user-apps              - Applications in ~/Applications"
  echo "  system-apps            - Applications in /System/Applications"
  echo "  pkg-receipts           - Package receipts in /var/db/receipts"
  echo "  install-history        - Installation history"
  echo "  all-users              - Applications for all users on the system"
  echo
  echo "Launch Services Types:"
  echo "  --all                  - All launch services"
  echo "  --user                 - User launch agents"
  echo "  --global               - Global launch agents and daemons"
  echo "  --system               - System launch agents and daemons"
  echo "  user-agents            - User launch agents"
  echo "  global-agents          - Global launch agents"
  echo "  system-agents          - System launch agents"
  echo "  global-daemons         - Global launch daemons"
  echo "  system-daemons         - System launch daemons"
  echo "  disabled               - Disabled launch services"
  echo
  echo "Options:"
  echo "  --output DIR           - Custom output directory"
  echo "  --analyze              - Run analysis after collection"
  echo "  --input DIR            - Input directory for analysis"
  echo
  echo "Examples:"
  echo "  macosapps collect --brew --mas --output ~/brew_mas_audit"
  echo "  macosapps collect homebrew-casks mas --analyze"
  echo "  macosapps launch-services --user --global"
  echo "  macosapps analyze --input ~/app_audit_data --output ~/app_report"
}

###############################################################################
#                                Examples                                     #
###############################################################################

# Add these functions to your .zshrc or save as a file and source it

# Example usage:
#
# # Check only Homebrew installations
# macosapps collect --brew --output ~/homebrew_audit
#
# # Compare Homebrew and Mac App Store
# macosapps collect --brew --mas --analyze
#
# # Check for duplicates across all installation methods
# macosapps collect --all --analyze
#
# # Focus only on launch services
# macosapps launch-services --all
#
# # Check just user-specific launch agents
# macosapps launch-services --user
#
# # Audit applications for a specific user
# sudo macosapps collect all-users --output ~/users_audit
#
# # Analyze previously collected data
# macosapps analyze --input ~/homebrew_audit --output ~/homebrew_report

# ========================================================================
# File & Directory Management
# ========================================================================

# Create and enter directory
function mkcd() {
  mkdir -p "$1" && cd "$1" || return 1
}

# Create symbolic link with parent directory creation if needed
function slink() {
  local src_orig="$1"
  local dst_link="$2"
  local dst_dir

  dst_dir=$(dirname "$dst_link")
  mkdir -p "$dst_dir"
  ln -sf "$src_orig" "$dst_link"
}

# Clean .DS_Store files
function clean_ds_store() {
  log_info "Cleaning .DS_Store files..."
  find "${1:-$DOTFILES}" -name ".DS_Store" -delete
  log_success "Finished cleaning .DS_Store files"
}

# Extract various archive formats
function extract() {
  if [[ ! -f "$1" ]]; then
    log_error "'$1' is not a valid file"
    return 1
  fi

  case "$1" in
  *.tar.bz2) tar xjf "$1" ;;
  *.tar.gz) tar xzf "$1" ;;
  *.bz2) bunzip2 "$1" ;;
  *.rar) unrar x "$1" ;;
  *.gz) gunzip "$1" ;;
  *.tar) tar xf "$1" ;;
  *.tbz2) tar xjf "$1" ;;
  *.tgz) tar xzf "$1" ;;
  *.zip) unzip "$1" ;;
  *.Z) uncompress "$1" ;;
  *.7z) 7z x "$1" ;;
  *) log_error "'$1' cannot be extracted" ;;
  esac
}

# Enhanced tree command with eza/exa if available
function lstree() {
  local level="${1:-2}"

  if command -v eza &>/dev/null; then
    eza --tree --level="$level" --icons
  elif command -v exa &>/dev/null; then
    exa --tree --level="$level" --icons
  else
    find . -type d -not -path "*/\.*" -not -path "*/node_modules/*" -maxdepth "$level" | sort | sed -e 's/[^-][^\/]*\//  |/g' -e 's/|\([^ ]\)/|-\1/'
  fi
}

# ========================================================================
# Directory Bookmarks
# ========================================================================

# Create directory bookmark
function bm() {
  local mark_dir="$XDG_DATA_HOME/marks"
  mkdir -p "$mark_dir"
  ln -sf "$(pwd)" "$mark_dir/$1"
  log_success "Created bookmark '$1' -> $(pwd)"
}

# List all bookmarks
function marks() {
  local mark_dir="$XDG_DATA_HOME/marks"
  if [[ ! -d "$mark_dir" ]]; then
    log_error "No bookmarks directory found at $mark_dir"
    return 1
  fi

  ls -l "$mark_dir" | sed 's/  / /g' | cut -d' ' -f9- | sed 's/ -/\t-/g'
}

# Jump to bookmark
function jump() {
  local mark_dir="$XDG_DATA_HOME/marks"
  local mark="$1"

  if [[ -L "$mark_dir/$mark" ]]; then
    cd "$(readlink "$mark_dir/$mark")" || return 1
  else
    log_error "No such bookmark: $mark"
    return 1
  fi
}

# ========================================================================
# Git Utilities
# ========================================================================

# Clean merged branches
function gclean() {
  local branches_to_delete

  branches_to_delete=$(git branch --merged | grep -v "^\*" | grep -v "master\|main\|develop")

  if [[ -z "$branches_to_delete" ]]; then
    log_info "No merged branches to delete."
    return 0
  fi

  echo "The following branches will be deleted:"
  echo "$branches_to_delete"
  read -q "REPLY?Are you sure you want to delete these branches? [y/N] "
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git branch --merged | grep -v "^\*" | grep -v "master\|main\|develop" | xargs git branch -d
    log_success "Branches deleted successfully!"
  else
    log_info "Operation canceled."
  fi
}

# ========================================================================
# Advanced Search with ripgrep + fzf + nvim
# ========================================================================
function rfv() {
  local RELOAD='reload:rg --column --color=always --smart-case {q} || :'
  local OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
                  vim {1} +{2}     # No selection. Open the current line in Vim.
                else
                  vim +cw -q {+f}  # Build quickfix list for the selected items.
                fi'

  fzf --disabled --ansi --multi \
    --bind "start:$RELOAD" --bind "change:$RELOAD" \
    --bind "enter:become:$OPENER" \
    --bind "ctrl-o:execute:$OPENER" \
    --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
    --delimiter : \
    --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
    --preview-window '~4,+{2}+4/3,<80(up)' \
    --query "$*"
}
