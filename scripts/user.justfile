# TODO: now just a soft symlink but .user.justfile should be real life in $HOME/.user.justfile


############################################################
# Justfile docs - https://just.systems/man/en/
# Justfile tips - https://www.stuartellis.name/articles/just-task-runner/
# Justfile cheatsheet https://cheatography.com/linux-china/cheat-sheets/justfile/
############################################################

############################################################
# Justfile settings (https://just.systems/man/en/chapter_26.html)
# TODO: [no-cd] recipe attribute -> if mod imported use parent cwd instead of child path (https://just.systems/man/en/chapter_32.html#disabling-changing-directory190)
############################################################

############################################################
# Justfile exporter (https://just.systems/man/en/chapter_74.html)
############################################################
# Justfile compat with NodeJS+package.json
export PATH := "./node_modules/.bin:" + env_var('PATH')

############################################################
# Justfile imports (other justfiles + modules)
# - modules : https://just.systems/man/en/chapter_54.html
############################################################
# import 'asdf/justfile'
# mod 'modNameFolderName' 'module path'

# set dotenv-filename := ".env.local"

# use dotfiles/.export.sh to set these env vars (or use default)
# user_justfile_name := env_var('USER_JUSTFILE_NAME', ".user.justfile")
# user_justfile_path := "{{ home_directory() }}/" + user_justfile_name
dotfiles_root_dir := justfile_directory() / "dotfiles"
dotfiles_home_root_dir := dotfiles_root_dir / "home"
dotenvx_root_dir := dotfiles_root_dir / "dotenvx"
nvm_root_dir := dotfiles_root_dir / "nvm"

# scripts_root_dir := dotfiles_root_dir / "scripts"
# chezmoi_root_dir := dotfiles_root_dir / "chezmoi"
# webi_root_dir := dotfiles_root_dir / "webi"

# List available recipes
# (TODO: update to add 2nd user justfile command to run aliased HOME dir user justfile)
help:
    @echo "dotfiles root dir: {{dotfiles_root_dir}}"
    @echo "dotfiles home root dir: {{dotfiles_home_root_dir}}"
    @just --unstable --list --unsorted -f "{{dotfiles_home_root_dir}}/.user.justfile"

# Display system information
system-info:
    @echo "CPU architecture: {{ arch() }}"
    @echo "Operating system type: {{ os_family() }}"
    @echo "Operating system: {{ os() }}"
    @echo "Home directory: {{ home_directory() }}"


##################################
# global user recipes (cwd = dotfiles root dir)
##################################
[no-cd]
run-recipe-user:
    @just --choose

# formats user.justfile and fixed in place
[no-cd]
fmt-user-justfile:
    @just --unstable --fmt

# checks user.justfile for syntax errors (return code 0 if no error)
[no-cd]
fmt-check-user-justfile:
    @just --unstable --fmt --check

brew-bundle:
    @brew bundle --file={{dotfiles_root_dir}}/Brewfile

##################################
# Project specific recipes (cwd = project root dir)
##################################
run-recipe-curr:
    @just --choose

# formats user.justfile and fixed in place
fmt-curr-justfile:
    @just --unstable --fmt

# checks curr project justfile for syntax errors (return code 0 if no error)
fmt-check-curr-justfile:
    @just --unstable --fmt --check

init-justfile-current-dir:
    @just --init




