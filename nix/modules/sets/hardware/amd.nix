{
  lib,
  config,
  ...
}: let
  name = "hardware.amd";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      hardware.graphics = {
        enable = true;
        # enable32Bit = true;
      };
    })
  ];
}
