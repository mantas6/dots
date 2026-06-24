{...}: {
  flake.nixosModules.base = {lib, ...}: {
    services.logind.settings.Login.HandlePowerKey = lib.mkDefault "poweroff";
  };
}
