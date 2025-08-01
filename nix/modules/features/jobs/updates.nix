{
  lib,
  config,
  ...
}: let
  name = "jobs/updates";
in {
  config = lib.mkMerge [
    {features.listAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.list) {
      system.autoUpgrade = {
        enable = true;
        flake = "github:mantas6/dots";
        allowReboot = true;
        rebootWindow = {
          lower = "01:00";
          upper = "03:00";
        };
      };
    })
  ];
}
