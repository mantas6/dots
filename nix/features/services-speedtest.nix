{...}: {
  flake.nixosModules."services-speedtest" = {
    lib,
    config,
    ...
  }: {
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
  };
}
