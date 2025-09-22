{...}: {
  imports = [
    ./tldr.nix
    ./pkgs.nix
  ];

  features.setsAvailable = ["develop"];
}
