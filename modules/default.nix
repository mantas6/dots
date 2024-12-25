{...}: {
  imports = [
    ./hardware
    ./pkgs
    ./services
    ./sets
    ./user
    ./bootloader.nix
    ./intl.nix
    ./network.nix
  ];
}
