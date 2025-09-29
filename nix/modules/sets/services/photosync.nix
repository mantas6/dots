# Work-in-progress/experimentation
{
  lib,
  config,
  ...
}: let
  name = "services.photosync";

  HOME = "/home/mantas";
  PHOTOSYNC_ORIGINALS = "${HOME}/Pictures/Gallery/Originals";
  PHOTOSYNC_SITE = "${HOME}/Pictures/Gallery/Site";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      services.caddy = {
        enable = true;
        user = "mantas";

        globalConfig = ''
          auto_https off
        '';

        virtualHosts = {
          "http://l4:8081" = {
            extraConfig = ''
              root * ${PHOTOSYNC_SITE}
                     file_server
            '';
          };
        };
      };
    })
  ];
}
