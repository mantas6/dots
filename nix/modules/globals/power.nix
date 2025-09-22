{lib, ...}: {
  services.logind.powerKey = lib.mkDefault "poweroff";
}
