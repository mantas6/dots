{...}: {
  flake.modules.nixos.base = {lib, ...}: {
    services.fail2ban.enable = lib.mkDefault true;
    services.fstrim.enable = true;
  };
}
