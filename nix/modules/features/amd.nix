{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (lib.elem "amd" config.features.list) {
    hardware.graphics = {
      enable = true;
      # enable32Bit = true;
    };
  };
}
