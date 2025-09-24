# dots

dotfiles

## Setup

### Change the shell

```sh
chsh -s $(which zsh)
```

### Clone the repo and link

```sh
git clone https://github.com/mantas6/dots.git "$HOME/.dots"
cd "$HOME/.dots"
./bin/dot/stw
```
If stow fails, remove conflicting files (preferably to trash) and run again. Pay close attention to the output to make sure that the links that it creates make sense.

### Create NixOS ISO

```sh
nix run nixpkgs#nixos-generators -- --format iso --flake #iso
```

### Deploy NixOS on the network

```sh
nixos-rebuild --flake .#host --target-host host --use-remote-sudo switch
```
