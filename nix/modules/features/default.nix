{
  lib,
  config,
  ...
}: {
  imports = [
    ./desktop
    ./develop
    ./disks
    ./quirks
    ./amd.nix
    ./nvidia.nix
    ./printing.nix
    ./backlight.nix
    ./docker.nix
  ];

  options = {
    features.listAvailable = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Define all available features";
    };

    features.list = lib.mkOption {
      type = lib.types.listOf (lib.types.enum config.features.listAvailable);
      default = [];
      description = "List of globally enabled features for this host.";
    };
  };
}
