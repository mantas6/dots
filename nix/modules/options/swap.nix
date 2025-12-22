{
  lib,
  config,
  ...
}: let
  size = config.features.swapSizeInGB;
in {
  options = {
    features.swapSizeInGB = lib.mkOption {
      type = lib.types.nullOr lib.types.float;
      default = null;
      example = 1.5;
      description = "Swapfile size in GB";
    };
  };
  config = lib.mkIf (size != null) {
    swapDevices = [
      {
        device = "/var/lib/swapfile";
        size = builtins.floor(size * 1024.0);
      }
    ];
  };
}
