{
  lib,
  config,
  ...
}: {
  imports = [
    ./xserver.nix
    ./fonts.nix
    ./audio.nix
    ./pkgs.nix
    ./pass.nix
    ./remap.nix
  ];

  config = lib.mkIf (lib.elem "desktop" config.features.list) {
    hardware.bluetooth.enable = true;
  };
}
