# git_utils.sh (POSIX-compliant; no 'local' or Bash‐only features)

######################
# Finds the top-level Git repository directory for a given file/directory path.
# Usage: get_repo_root [path]
#        If no path is provided, defaults to $0 (the calling script).
#
# Call the function to get the repo root of this script's location
###################### Usage example
# #!/bin/sh
# some_script.sh
#
# # Source the utilities
# . /path/to/git_utils.sh
#
# # Call the function to get the repo root of this script's location
# root_dir=$(get_repo_root "$0")
# echo "Repository root: $root_dir"
#
# (optionally, pass a different path (e.g., a subdirectory) instead of $0 if needed
#
# other_root=$(get_repo_root "/some/other/path")
# echo "Repository root for that path: $other_root"
######################
get_repo_root() {
  file="${1:-$0}"

  # Save the current directory to restore later
  saved_pwd=$(pwd)

  # cd to the directory of the provided path (resolving any symlinks if possible)
  script_dir=$(CDPATH= cd -- "$(dirname -- "$file")" && pwd -P) || {
    printf "Error: Failed to cd into '%s'\n" "$file" >&2
    return 1
  }

  cd "$script_dir" || {
    printf "Error: Cannot cd to script directory '%s'\n" "$script_dir" >&2
    return 1
  }

  # Obtain the top-level Git directory; exit non-zero on failure
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    printf "Error: '%s' is not in a Git repository.\n" "$script_dir" >&2
    cd "$saved_pwd" || exit 1
    return 1
  }

  # Return to original directory
  cd "$saved_pwd" || exit 1

  # Output the Git root
  printf "%s\n" "$repo_root"
}
