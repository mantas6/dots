{...}: {
  flake.nixosModules."services-photosync" = {
    lib,
    config,
    ...
  }: let
    HOME = "/home/mantas";
    PHOTOSYNC_ORIGINALS = "${HOME}/Pictures/Gallery/Originals";
    PHOTOSYNC_SITE = "${HOME}/Pictures/Gallery/Site";
  in {
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
  };
}
