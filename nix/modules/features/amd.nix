{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (lib.elem "amd" config.features) {
    hardware.graphics = {
      enable = true;
      # enable32Bit = true;
    };
  };
}
