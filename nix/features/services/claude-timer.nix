{...}: {
  flake.modules.nixos."services-claude-timer" = {
    pkgs-unstable,
    lib,
    inputs,
    ...
  }: let
    pkgs-unstable-unfree = import inputs.nixpkgs-unstable {
      system = pkgs-unstable.stdenv.hostPlatform.system;
      config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) ["claude-code"];
    };
  in {
    systemd.user.services.claude-timer = {
      description = "Run claude -p hi";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.ConditionUser = "!root";
      serviceConfig = {
        Type = "oneshot";
        WorkingDirectory = "/tmp";
        ExecStart = "${pkgs-unstable-unfree.claude-code}/bin/claude -p hi";

        TimeoutStartSec = "5min";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };

    systemd.user.timers.claude-timer = {
      description = "Run claude -p hi at 06:00 and 12:00";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = ["*-*-* 05:00:00" "*-*-* 10:15:00"];
        Persistent = false;
        RandomizedDelaySec = "5min";
      };
    };
  };
}
