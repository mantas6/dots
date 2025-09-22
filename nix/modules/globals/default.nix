{...}: {
  imports = [
    ./pkgs
    ./services
    ./user
    ./bootloader.nix
    ./locale.nix
    ./network.nix
    ./power.nix
    ./shell.nix
  ];
}
