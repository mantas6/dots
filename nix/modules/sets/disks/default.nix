{inputs, ...}: {
  imports = [
    inputs.disko.nixosModules.disko
    ./normal.nix
    ./encrypted.nix
  ];
}
