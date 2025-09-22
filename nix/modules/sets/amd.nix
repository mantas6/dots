{
  lib,
  config,
  ...
}: let
  name = "amd";
in {
  config = lib.mkMerge [
    {features.listAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.list) {
      hardware.graphics = {
        enable = true;
        # enable32Bit = true;
      };
    })
  ];
}
