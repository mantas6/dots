{...}: {
  flake.nixosModules."collections-develop" = {pkgs-unstable, ...}: let
    serviceName = "tldr-update";
  in {
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

      startAt = "weekly";
    };

    systemd.user.timers.${serviceName} = {
      timerConfig = {
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
