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
    ./jobs
    ./hardware
    ./services
    ./purposes
  ];

  options = {
    features.setsAvailable = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Define all available features";
    };

    features.sets = lib.mkOption {
      type = lib.types.listOf (lib.types.enum config.features.setsAvailable);
      default = [];
      description = "List of globally enabled features for this host.";
    };
  };
}
