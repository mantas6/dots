{
  pkgs,
  lib,
  config,
  ...
}: let
  serviceName = "tldr-update";
in {
  config = lib.mkIf (lib.elem "develop" config.features) {
    systemd.user.services.${serviceName} = {
      script = "${pkgs.tealdeer}/bin/tldr -u";

      serviceConfig = {
        Type = "oneshot";
        After = "network-online.target";
        Wants = "network-online.target";
      };
    };

    systemd.user.timers.${serviceName} = {
      wantedBy = ["timers.target"];

      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        AccuracySec = "6h";
        RandomizedDelaySec = "1h";
        Unit = "${serviceName}.service";
      };
    };
  };
}
