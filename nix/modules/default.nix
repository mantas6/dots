{...}: {
  imports = [
    ./pkgs
    ./services
    ./features
    ./user
    ./bootloader.nix
    ./locale.nix
    ./network.nix
    ./power.nix
    ./shell.nix
  ];
}
