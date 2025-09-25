{
  lib,
  config,
  ...
}: let
  name = "services.photosync";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      #
    })
  ];
}

