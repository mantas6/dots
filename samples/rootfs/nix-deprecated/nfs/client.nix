{
  lib,
  config,
  ...
}: {
  options = {
    shares.client.enabled = lib.mkEnableOption "Enable NFS client";
  };

  config = lib.mkIf config.shares.client.enabled {
    fileSystems."/mnt/nfs" = {
      device = "l4:/";
      fsType = "nfs";

      options = [
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=60"
      ];
    };
  };
}
