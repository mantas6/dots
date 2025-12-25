{
  lib,
  config,
  ...
}: {
  imports = [
    ./disks
    ./quirks
    ./jobs
    ./hardware
    ./services
    ./purposes
    ./collections
    ./progs
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
