{
  lib,
  config,
  ...
}: let
  size = config.features.swapSizeInGB;
in {
  options = {
    features.swapSizeInGB = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 2;
      description = "Swapfile size in GB";
    };
  };
  config = lib.mkIf (size != null) {
    swapDevices = [
      {
        device = "/var/lib/swapfile";
        size = size * 1024;
      }
    ];
  };
}
