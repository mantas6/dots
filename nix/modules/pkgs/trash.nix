{pkgs-unstable, ...}: let
  serviceName = "trash-empty";
in {
  environment.systemPackages = with pkgs-unstable; [
    trash-cli
  ];

  systemd.user.services.${serviceName} = {
    script = "${pkgs-unstable.trash-cli}/bin/trash-empty -vf 90";

    serviceConfig = {
      Type = "oneshot";
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
}
