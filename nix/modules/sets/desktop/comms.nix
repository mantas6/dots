{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (lib.elem "desktop" config.features.list) {
    hardware.bluetooth.enable = true;
  };
}
