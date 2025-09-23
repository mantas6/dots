{
  lib,
  config,
  ...
}: let
  name = "services.memos";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      # move to global place
      virtualisation.oci-containers.backend = "docker";

      virtualisation.oci-containers.containers = {
        memos = {
          image = "neosmemo/memos:0.25.1";
          user = "1000";
          ports = ["0.0.0.0:5230:5230"];
          volumes = [
            "/home/mantas/Volumes/memos:/var/opt/memos"
          ];
        };
      };
    })
  ];
}
