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
      virtualisation.oci-containers.containers = {
        memos = {
          # image = "neosmemo/memos:0.25.1";
          image = "neosmemo/memos:stable";
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
