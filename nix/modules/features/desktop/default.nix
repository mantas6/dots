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
  ];

  config = lib.mkIf (lib.elem "desktop" config.features) {
    hardware.bluetooth.enable = true;
  };
}
