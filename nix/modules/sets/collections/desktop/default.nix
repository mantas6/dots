{...}: {
  imports = [
    ./xserver.nix
    ./fonts.nix
    ./audio.nix
    ./pkgs.nix
    ./pass.nix
    ./remap.nix
    ./services.nix
    ./browsers.nix
  ];

  features.setsAvailable = ["collections.desktop"];
}
