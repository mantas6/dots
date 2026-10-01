{...}: {
  flake.modules.nixos."jobs-dots-sync" = {
    lib,
    config,
    ...
  }: let
    user = config.users.users.mantas;
    zsh = lib.getExe user.shell;
  in {
    systemd.services.dots-sync = {
      description = "Sync dotfiles (dsy)";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      environment.SHELL = zsh;
      serviceConfig = {
        Type = "oneshot";
        User = "mantas";
        WorkingDirectory = user.home;
        ExecStart = "${zsh} -lc 'exec dsy'";

        TimeoutStartSec = "15min";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };

    systemd.timers.dots-sync = {
      description = "Sync dotfiles (dsy) daily";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "15min";
      };
    };
  };
}
