{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (lib.elem "collections.desktop" config.features.sets) {
    hardware.bluetooth.enable = true;

    services.udisks2.enable = true;
  };
}
