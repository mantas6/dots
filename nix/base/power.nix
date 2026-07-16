{...}: {
  flake.modules.nixos.base = {lib, ...}: {
    services.logind.settings.Login.HandlePowerKey = lib.mkDefault "poweroff";
  };
}
