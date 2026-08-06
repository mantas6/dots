{...}: {
  flake.modules.nixos.base = {...}: {
    services.fail2ban.enable = true;
    services.fstrim.enable = true;
  };
}
