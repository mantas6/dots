{lib, ...}: {
  networking = {
    interfaces = {
      eth0.wakeOnLan.enable = true;
      eth1.wakeOnLan.enable = true;
    };

    usePredictableInterfaceNames = false;

    firewall.enable = lib.mkDefault false;
  };
}
