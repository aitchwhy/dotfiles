
  # Symlink .zshenv from dotfiles
  backup_if_exists "${HOME}/.zshenv"
  ln -sf "${dotfiles_dir}/home/zshenv" "${HOME}/.zshenv"
  log_info "Symlinked .zshenv"

  # Install/Update Antidote
  local antidote_dir="${zsh_config}/.antidote"
  if [[ ! -d "$antidote_dir" ]]; then
    log_info "Installing Antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir"
  else
    log_info "Updating Antidote..."
    (cd "$antidote_dir" && git pull --rebase --autostash)
  fi

  # Symlink all Zsh config files
  local zsh_files=(
    ".zshrc"
    "aliases.zsh"
    "env.zsh"
    "functions.zsh"
    "macos.zsh"
    "plugins.txt"
  )

  for fname in "${zsh_files[@]}"; do
    local source_file="${dotfiles_zsh}/${fname}"
    local target_file="${zsh_config}/${fname}"

    if [[ -f "$source_file" ]]; then
      backup_if_exists "$target_file"
      ln -sf "$source_file" "$target_file"
      log_info "Symlinked ${fname}"
    else
      log_error "File not found: $source_file. Skipping."
    fi
  done

  # Generate static plugins file
  if [[ -f "${zsh_config}/plugins.txt" ]]; then
    if command -v antidote &>/dev/null; then
      log_info "Generating .plugins.zsh from plugins.txt..."
      antidote bundle <"${zsh_config}/plugins.txt" >"${zsh_config}/.plugins.zsh"
    else
      log_info "Generating .plugins.zsh using local antidote..."
      "${antidote_dir}/antidote.zsh" bundle <"${zsh_config}/plugins.txt" >"${zsh_config}/.plugins.zsh"
    fi
  fi

  log_success "Zsh configuration complete"