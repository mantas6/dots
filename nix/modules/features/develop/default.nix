{...}: {
  imports = [
    ./tldr.nix
    ./pkgs.nix
  ];

  features.listAvailable = ["develop"];
}
