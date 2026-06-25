{...}: {
  flake.nixosModules."services-memos" = {
    lib,
    config,
    ...
  }: {
    virtualisation.oci-containers.containers = {
      memos = {
        image = "neosmemo/memos:0.28";
        user = "1000";
        ports = ["0.0.0.0:5230:5230"];
        volumes = [
          "/home/mantas/Volumes/memos:/var/opt/memos"
        ];
      };
    };
  };
}
