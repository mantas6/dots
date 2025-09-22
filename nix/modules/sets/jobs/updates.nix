{
  lib,
  config,
  ...
}: let
  name = "jobs/updates";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      system.autoUpgrade = {
        enable = true;

        persistent = false;

        flake = "github:mantas6/dots";
        dates = "01:00";

        allowReboot = true;
        rebootWindow = {
          lower = "01:00";
          upper = "03:00";
        };
      };
    })
  ];
}
