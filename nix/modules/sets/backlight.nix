{
  lib,
  config,
  pkgs,
  ...
}: let
  name = "backlight";
in {
  config = lib.mkMerge [
    {features.listAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.list) {
      environment.systemPackages = with pkgs; [
        brightnessctl
      ];

      services.udev.extraRules =
        /*
        udev
        */
        ''
          ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video $sys$devpath/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w $sys$devpath/brightness"
        '';

      users.users.mantas = {
        extraGroups = ["video"];
      };
    })
  ];
}
