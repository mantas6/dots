{
  lib,
  config,
  pkgs,
  ...
}: let
  name = "progs.gaming";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      programs.steam = {
        enable = true;
      };

      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "steam"
          "steam-unwrapped"
        ];
    })
  ];
}
