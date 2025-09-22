{
  lib,
  config,
  pkgs-unstable,
  ...
}: let
  serviceName = "tldr-update";
in {
  config = lib.mkIf (lib.elem "collections.develop" config.features.sets) {
    environment.systemPackages = with pkgs-unstable; [
      tealdeer
    ];

    systemd.user.services.${serviceName} = {
      script = "${pkgs-unstable.tealdeer}/bin/tldr -u";

      after = ["network-online.target"];
      wants = ["network-online.target"];

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      serviceConfig = {
        Type = "oneshot";
      };
    };

    systemd.user.timers.${serviceName} = {
      wantedBy = ["timers.target"];

      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "5m";
        Unit = "${serviceName}.service";
      };
    };
  };
}
