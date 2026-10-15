{...}: {
  flake.modules.nixos.base = {config, ...}: {
    services.fail2ban = {
      enable = config.networking.firewall.enable;

      # Repeat offenders get doubling bans instead of a flat 10m.
      bantime-increment = {
        enable = true;
        maxtime = "1w";
      };

      # sshd logs at VERBOSE, so the aggressive filter can match more probe patterns.
      jails.sshd.settings.mode = "aggressive";
    };

    services.fstrim.enable = true;
  };
}
