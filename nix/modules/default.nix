{...}: {
  imports = [
    ./pkgs
    ./services
    ./sets
    ./options
    ./user
    ./bootloader.nix
    ./locale.nix
    ./network.nix
    ./power.nix
    ./shell.nix
  ];
}
