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

    restartIfChanged = false;
    unitConfig.X-StopOnRemoval = false;

    startAt = "weekly";
  };

  systemd.user.timers.${serviceName} = {
    timerConfig = {
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };
}
