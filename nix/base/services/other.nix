{...}: {
  flake.modules.nixos.base = {config, ...}: {
    services.fail2ban.enable = config.networking.firewall.enable;
    services.fstrim.enable = true;
  };
}
