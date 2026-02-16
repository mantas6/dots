{
  lib,
  config,
  pkgs,
  ...
}: let
  name = "progs.art";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      environment.systemPackages = with pkgs; [
        gimp
        natron
        ffmpeg-full
        kdePackages.kdenlive
        audacity
      ];
    })
  ];
}
