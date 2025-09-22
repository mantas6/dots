{
  lib,
  config,
  ...
}: let
  name = "docker";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      virtualisation.docker = {
        enable = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };

      boot.kernel.sysctl = {
        "net.ipv4.ip_unprivileged_port_start" = 0;
      };
    })
  ];
}
