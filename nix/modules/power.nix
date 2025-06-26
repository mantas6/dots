{lib, ...}: {
  services.logind.powerKey = lib.mkDefault "suspend";
}
