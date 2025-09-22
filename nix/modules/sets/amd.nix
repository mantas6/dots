{
  lib,
  config,
  ...
}: let
  name = "amd";
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
