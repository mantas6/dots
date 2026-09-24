{...}: {
  flake.modules.nixos."agents-codex-timer" = {pkgs-unstable, ...}: {
    systemd.user.services.codex-timer = {
      description = "Run codex exec hi";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.ConditionUser = "!root";
      serviceConfig = {
        Type = "oneshot";
        WorkingDirectory = "/tmp";
        ExecStart = "${pkgs-unstable.codex}/bin/codex exec --skip-git-repo-check --ephemeral --sandbox read-only -m gpt-5.6-luna -c model_reasoning_effort=low hi";

        TimeoutStartSec = "5min";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };

    systemd.user.timers.codex-timer = {
      description = "Run codex exec hi at 05:00 and 10:15";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = ["*-*-* 05:00:00" "*-*-* 10:15:00"];
        Persistent = false;
        RandomizedDelaySec = "5min";
      };
    };
  };
}
