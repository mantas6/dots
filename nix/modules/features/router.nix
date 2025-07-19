{
  lib,
  config,
  ...
}: let
  name = "router";
in {
  config = lib.mkMerge [
    {features.listAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.list) {
      #
    })
  ];
}
