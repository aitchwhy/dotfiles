#  dotfiles

## References

- TODO: https://randomgeekery.org/config/shell/zsh/
- https://claude.ai/chat/3aa18a69-65af-499a-b849-29e633ad15dc
- https://chatgpt.com/c/67a3ecfb-9f94-8012-9c66-fd98cd4bb5b2
- https://github.com/getantidote/zdotdir/blob/main/.zshenv


## (1) clone dotfiles into (~/dotfiles)

```
git clone https://github.com/aitchwhy/dotfiles.git ~/dotfiles
```

## (2) Run init

```shell
chmod +x $HOME/dotfiles/init.sh

$HOME/dotfiles/init.sh
```


## (3) Setup

Zsh shell  needs setting up
```shell
# ~/.zshenv
```

```
# ~/.zshrc
ln -sf ~/path/to/dotfiles/.zshrc ~/.zshrc
```

