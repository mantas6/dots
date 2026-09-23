{...}: {
  flake.modules.nixos.base = {
    lib,
    config,
    ...
  }: let
    size = config.features.swapSizeInGB;
  in {
    options = {
      features.swapSizeInGB = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = 2;
        example = 2;
        description = "Swapfile size in GB (set to null to disable)";
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
  };
}
