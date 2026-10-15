{...}: {
  flake.modules.nixos."collections-develop" = {pkgs-unstable, ...}: let
    serviceName = "tldr-update";
  in {
    environment.systemPackages = with pkgs-unstable; [
      tealdeer
    ];

    systemd.services.${serviceName} = {
      script = "${pkgs-unstable.tealdeer}/bin/tldr -u";

      after = ["network-online.target"];
      wants = ["network-online.target"];

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      serviceConfig = {
        Type = "oneshot";
        User = "mantas";
      };

      startAt = "weekly";
    };

    systemd.timers.${serviceName} = {
      timerConfig = {
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
