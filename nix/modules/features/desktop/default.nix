{
  ...
}: {
  imports = [
    ./xserver.nix
    ./fonts.nix
    ./audio.nix
    ./pkgs.nix
    ./pass.nix
    ./remap.nix
    ./comms.nix
  ];

  features.listAvailable = ["desktop"];
}
