# Git global setup

```shell
# link home dir file to config file (if needed) <--- TODO: this should be created by Nix+dotfiles
$ ln -s ~/src/dotfiles/config/git/.gitignore ~/.gitignore
# set global gitignore to "~/.gitignore" file
$ git config --global core.excludesfile ~/.gitignore
```
