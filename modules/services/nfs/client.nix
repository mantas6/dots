{
  fileSystems."/mnt/nfs" = {
    device = "l4:/";
    fsType = "nfs";

    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
    ];
  };
}
