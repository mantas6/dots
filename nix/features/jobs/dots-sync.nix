{...}: {
  flake.modules.nixos."jobs-dots-sync" = {
    lib,
    config,
    ...
  }: let
    zsh = lib.getExe config.users.users.${config.features.serviceUser}.shell;
  in {
    systemd.user.services.dots-sync = {
      description = "Sync dotfiles (dsy)";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.ConditionUser = config.features.serviceUser;
      environment.SHELL = zsh;
      serviceConfig = {
        Type = "oneshot";
        WorkingDirectory = "%h";
        ExecStart = "${zsh} -lc 'exec dsy'";

        TimeoutStartSec = "15min";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };

    systemd.user.timers.dots-sync = {
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
