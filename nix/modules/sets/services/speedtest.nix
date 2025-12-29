{
  lib,
  config,
  ...
}: let
  name = "services.speedtest";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      virtualisation.oci-containers.containers = {
        speedtest = {
          image = "ghcr.io/librespeed/speedtest:5.4.1";
          user = "1000";
          ports = ["0.0.0.0:6001:8080"];

          environment = {
            MODE = "standalone";
            TELEMETRY = "true";
            DB_TYPE = "sqlite";
            WEBPORT = "8080";
          };

          volumes = [
            "/home/mantas/Volumes/speedtest:/database"
          ];
        };
      };
    })
  ];
}
