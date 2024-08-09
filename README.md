# dotfiles

Environment setup files for OSX setup

- https://terminaltrove.com/language/rust/

# Aug 9 2024 (zsh autocomplete + use ZDOTDIR setup to avoid using frameworks like OMZ)

- add zsh-completions as git submodule (additional CLI program completions) - https://github.com/Phantas0s/.dotfiles/blob/master/.gitmodules
- https://github.com/zsh-users/zsh-completions
- https://github.com/zsh-users/zsh-completions/blob/master/zsh-completions-howto.org
- https://thevaluable.dev/zsh-install-configure-mouseless/ + https://github.com/Phantas0s/.dotfiles/blob/master/zsh/zshenv
- zsh syntax highlighting (https://github.com/zsh-users/zsh-syntax-highlighting)

## Nix-based dotfiles setup (Jun 18) - (nix-direnv)

- to run locally cloned GH repo, run nix-darwin with "-I darwin=." after cd-ing to dotfiles dir.
- This will point to curr dir & expect a flake (so need to supply "--flake=." too)

```bash
$ cd ~/dotfiles
$ nix run nix-darwin -- switch -I darwin=. --flake .
```

## Nix-based dotfiles setup (Jun 17)

- open built-in Terminal App (should be bash shell by default)
- install darwin (macos) dependencies (`$ xcode-select --install`)
- fetch dotfiles (`$ git clone https://github.com/aitchwhyz/dotfiles.git`)
- Resources for dotfiles
  - https://github.com/mitchellh/nixos-config/blob/main/machines/macbook-pro-m1.nix
  - https://github.com/dustinlyons/nixos-config?tab=readme-ov-file#for-macos-june-2024
  - https://evantravers.com/articles/2024/02/06/switching-to-nix-darwin-and-flakes/
  - https://github.com/evantravers/dotfiles/tree/master/home
  - https://mirosval.sk/blog/2023/nix-getting-started/

# Dotfiles setup (May 2, 2024 ~)

Use tools below
(bootstrap.sh should be updated to reflect this but WIP)

- (blank state)
- webi (web installer scripts) : to get started installing basic setup
  - install webi : `curl -sS https://webi.sh/webi | sh`
  - core tools using webi
    - git+curl (for asdf)
    - brew
    - pathman
    - aliasman
- asdf (tooling manager)
  - (Git method) asdf download : `git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0`
  - (chezmoi should do this but just in case) setup asdf by appending to `.zshrc` the line `. "$HOME/.asdf/asdf.sh"`
  - install asdf-chezmoi for dotfiles and pull from personal GH dotfiles Github Repo (this project hosted on cloud)
- chezmoi (dotfiles manager) : keeps dotfiles synced between machines
  - NOTE: uses "dotfiles/darwin" as chezmoi root when pulling from remote Github repo (configured by "dotfiles/.chezmoiroot" - `https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/`)
  - on chezmoi init (from GH dotfiles repo) install and configure secrets+credentials using Password Manager Bitwarden + CLI
    - (`https://www.chezmoi.io/user-guide/password-managers/bitwarden/`) + (`https://www.chezmoi.io/user-guide/advanced/install-your-password-manager-on-init/`)
    - secrets (SSH, AWS, GH, etc) setup on local filesystem via from Bitwarden CLI
- asdf (again but this time install ALL tools from chezmoi pulled dotfile `.asdfrc` + `$HOME/.tool-versions`)
  - core tools like (zsh + iterm2 + nerdfont + dotenv + watchexec + bat + curlie + delta + eza + zoxide + vim + direnv + jq + atuin + rg + etc)
  - ... direnv/asdf-direnv + zsh + pyenv + node + prettier + asdf-zoxide + fx + fzf + github-cli + asdf-uv + justfile + tmux + + etc
- (TODO) custom Hank shell scripts? Symlinks? Aliases? VSCode setup? Global ignore files (gitignore, etc)
- (TODO) Nix + Homebrew for rest of setup
  - Nix
    - nix-darwin (Mac configs)
    - home-manager (`https://github.com/nix-community/home-manager`) + `https://home-manager-options.extranix.com/`
      - `https://github.com/breuerfelix/dotfiles/tree/main/home-manager`
      - `https://github.com/juspay/nix-dev-home`j
      - `https://devenv.sh/`
      - `https://flakehub.com/`
- (finally setup full state)

---

## Archive (as of May 2, 2024)

## 0. Hardware setup

- update modifier keys (e.g. Caps lock -> Ctrl)
- enable key hold [link](https://www.macworld.com/article/351347/how-to-activate-key-repetition-through-the-macos-terminal.html)

```
defaults write -g ApplePressAndHoldEnabled -bool false
```

## 1. Xcode Installation + other App Store apps

Install Brew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Need to install Xcode CLI tools. Install them from the App Store

After installation, run the following command in the shell

```bash
~ $ sudo xcodebuild -license accept # License agreement (accept all)
~ $ xcode-select --install   # Command Line Tool installation
```

## 2. SSH setup

Generate appropriate SSH key pairs on Github (or other repository service)

[Github SSH help link](https://help.github.com/articles/connecting-to-github-with-ssh/)

## 3. Install dotfiles setup

Make sure the dotfiles directory is downloaded to $HOME directory

## 4. Run dotfiles setup

Open necessary files to update correct Git user info

```bash
# ~/dotfiles/scripts/.extra.sh <--- copy afresh from .extra.sh.template

WORKSPACE_ROOT=$HOME/workspace
GIT_USER_NAME="foo"
GIT_EMAIL="foo@bar.com"
```

Run dotfiles setup script

```bash
~/dotfiles $ bash bootstrap.sh # (v1) TODO: deprecate
~/dotfiles $ bash setup.sh # (v2)
```

## 5. Iterm2 setup

### Change iterm2 font to one that supports Powerline

Install Google Material color scheme for Iterm2 (or whichever color preset you'd like)

- [Google's Material Design Color Palette for Iterm2](https://github.com/MartinSeeler/iterm2-material-design)

### Update iTerm2 key for FZF

- (Pref -> Profiles -> Keys -> Left Option Key = Esc+)

## App Store setup (listed in Brewfile as 'mas' deps)

- [mas CLI (for Mac App Store)](https://github.com/mas-cli/mas)

## main tools configuration setup

### Vim

- install Vim plugins (in .vimrc) by entering vim in shell, and then ":PlugInstall"

### Python (installed by Brewfile)

- [pyenv](https://github.com/pyenv/pyenv) ---> shoudl be installed by Homebrew

```shell
pyenv install 3.10 # installs python version (3.10)
pyenv versions # list installed python versions
pyenv global 3.10 # set global default version
```

### Node/nvm (nvm installed by Brewfile)

- nvm install global version

```shell
$ nvm install node # installs latest "node" version
$ nvm ls
$ nvm alias default node # set global default version
# ...
$ nvm use node # specify a version of node to use now
```

### VSCode

- login to Github user for settings sync
- most custom changes are in Bear notes tag "vscode"

### Datagrip

- login to Jetbrains user for settings sync
- most custom changes are in Bear notes tag "datagrip"

### Direnv

- [Automatically Activate env - Direnv](https://direnv.net/)
