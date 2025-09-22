{...}: {
  imports = [
    ./tldr.nix
    ./programs.nix
  ];

  features.setsAvailable = ["collections.develop"];
}
