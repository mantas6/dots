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

      users.users.mantas = {
        extraGroups = ["video"];
      };
    })
  ];
}
