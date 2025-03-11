{...}: {
  imports = [
    ./pkgs
    ./services
    ./features
    ./user
    ./bootloader.nix
    ./intl.nix
    ./network.nix
    ./power.nix
  ];
}
