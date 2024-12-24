{
  lib,
  config,
  ...
}: {
  options = {
    shares.server.enabled = lib.mkEnableOption "Enable NFS server";
  };

  config = lib.mkIf config.shares.server.enabled {
    fileSystems."/export/storage" = {
      device = "/mnt/nfs";
      options = ["bind"];
    };

    services.nfs.server.enable = true;
    services.nfs.server.exports = ''
      /export         192.168.0.0/24(rw,fsid=root)
      /export/storage 192.168.0.0/24(rw)
    '';
  };
}
