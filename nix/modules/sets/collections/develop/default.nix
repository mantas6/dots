{...}: {
  imports = [
    ./tldr.nix
    ./pkgs.nix
  ];

  features.setsAvailable = ["collections.develop"];
}
