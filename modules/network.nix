{lib,...}: {
  networking.interfaces.eth0.wakeOnLan.enable = true;
  networking.usePredictableInterfaceNames = false;

  networking.firewall.enable = lib.mkDefault false;
}
