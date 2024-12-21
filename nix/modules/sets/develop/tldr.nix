{pkgs, ...}:
let
  serviceName = "tldr-update";
in {
  systemd.user.services.${serviceName} = {
    script = "${pkgs.tealdeer}/bin/tldr -u";

    serviceConfig = {
      Type = "oneshot";
    };
  };

  systemd.user.timers.${serviceName} = {
    wantedBy = ["timers.target"];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      Unit = "${serviceName}.service";
    };
  };
}
