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

### Install NixOS

Normal setup:

```sh
nix run nixpkgs#nixos-anywhere -- \
    --flake ".#__host__" \
    --generate-hardware-config nixos-generate-config nix/hosts/__host__/hardware.nix \
    --target-host "root@__host__"
```

Encrypted setup:

```sh
nix run nixpkgs#nixos-anywhere -- \
    --flake ".#__host__" \
    --disk-encryption-keys /tmp/secret.key <(pass "hosts/__host__") \
    --generate-hardware-config nixos-generate-config nix/hosts/"__host__"/hardware.nix \
    --target-host "root@__host__"
```

### Deploy NixOS on the network

```sh
nixos-rebuild --flake .#__host__ --target-host root@__host__ switch
```

## Additional

### Upgrade out-dated dotfiles

Run when need to migrate old version of dotfiles structure

```sh
cd "$HOME/.dots"
./bin/dot/stw -D
git pull
./bin/dot/stw
```
