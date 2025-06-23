{
  lib,
  config,
  pkgs,
  ...
}: let
  name = "printing";
in {
  config = lib.mkMerge [
    {features.listAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.list) {
      services = {
        printing.enable = true;

        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
      };

      environment.systemPackages = with pkgs; [
        mandoc
      ];
    })
  ];
}
