{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (config.gpu.type == "amd") {
    hardware.graphics = {
      enable = true;
      # enable32Bit = true;
    };
  };
}
