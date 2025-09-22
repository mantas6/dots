{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (lib.elem "desktop" config.features.sets) {
    hardware.bluetooth.enable = true;
  };
}
