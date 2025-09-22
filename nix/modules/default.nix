{...}: {
  imports = [
    ./pkgs
    ./services
    ./sets
    ./user
    ./bootloader.nix
    ./locale.nix
    ./network.nix
    ./power.nix
    ./shell.nix
  ];
}
