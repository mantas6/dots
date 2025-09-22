{
  lib,
  config,
  pkgs-unstable,
  ...
}: let
  serviceName = "tldr-update";
in {
  config = lib.mkIf (lib.elem "develop" config.features.sets) {
    environment.systemPackages = with pkgs-unstable; [
      tealdeer
    ];

    systemd.user.services.${serviceName} = {
      script = "${pkgs-unstable.tealdeer}/bin/tldr -u";

      serviceConfig = {
        Type = "oneshot";
        After = "network-online.target";
        Wants = "network-online.target";
      };
    };

    systemd.user.timers.${serviceName} = {
      wantedBy = ["timers.target"];

      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        AccuracySec = "6h";
        RandomizedDelaySec = "1h";
        Unit = "${serviceName}.service";
      };
    };
  };
}
