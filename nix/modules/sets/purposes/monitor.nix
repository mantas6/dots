{
  lib,
  config,
  ...
}: let
  name = "purposes.monitor";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      services = {
        xserver = {
          enable = true;

          windowManager.awesome.enable = true;

          displayManager.startx = {
            enable = true;
            generateScript = true;
          };
        };

        getty.autologinUser = "mantas";
      };
    })
  ];
}
