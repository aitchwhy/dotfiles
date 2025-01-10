# dotfiles (nix)


## TODOs

- [ ] add README instructions
  - [ ] how to install Determinate Nix -> `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
  - [ ] how to setup + run dotfiles for nix-darwin + home-manager
- [ ] split up packages + import config files like [evan travers link](https://github.com/evantravers/dotfiles/blob/master/home-manager/default.nix)
- [devenv](https://github.com/cachix/devenv)
- [cachix](https://www.cachix.org/)
- [flake.parts](https://github.com/hercules-ci/flake-parts) - Minimal Nix modules framework for Flakes: split your flakes into modules and get things done with community modules.
- [flake-utils](https://github.com/numtide/flake-utils) - Pure Nix flake utility functions to help with writing flakes.
- [flake-utils-plus](https://github.com/gytis-ivaskevicius/flake-utils-plus) - A lightweight Nix library flake for painless NixOS flake configuration.
- lorri
- nix-direnv
- nixd 
- nil + nixd - nix lang servers
- bento - deployment tool
- kubenix
- kubernix
- nixery
- nixops
- deadnix
- nix-diff

## Usage

install nil (nix LSP server) with
```shell
nix profile install nixpkgs#nil
```


Install first time (TODO: use github repo URL for 1st time install instead of local)
```shell
nix run nix-darwin -- switch --flake ~/dotfiles/darwin

# TODO : nix run nix-darwin -- switch --flake github:aitchwhy/dotfiles
```

Apply changes using nix-darwin's darwin-rebuild (after 1st install)
```shell
darwin-rebuild switch -I darwin-config=$HOME/dotfiles/darwin/configuration.nix
# NOT(?) darwin-rebuild switch --flake ~/dotfiles/darwin
```


## Resources

- [nixOS concepts](https://nixos.wiki/wiki/User_Environment#nix.conf)
- [evantravers dotfiles](https://github.com/evantravers/dotfiles) + [evantravers dotfiles older]
- [nix apps](https://nixos.wiki/wiki/Applications)
- [nix-darwin manual](https://daiderd.com/nix-darwin/manual/index.html)
- [HM options](https://home-manager-options.extranix.com/?query=&release=release-24.11)
- [HM options search](https://home-manager-options.extranix.com/)
- [awesome-nix](https://github.com/nix-community/awesome-nix)