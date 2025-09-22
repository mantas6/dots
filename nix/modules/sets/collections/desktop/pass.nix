{
  lib,
  config,
  pkgs,
  ...
}: let
  serviceName = "pass-pull";
in {
  config = lib.mkIf (lib.elem "collections.desktop" config.features.sets) {
    programs.gnupg = {
      agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-gtk2;
      };
    };

    environment.systemPackages = with pkgs; [
      pass
      rofi-pass
      pwgen
    ];

    systemd.user.services.${serviceName} = {
      script = "${pkgs.pass}/bin/pass git pull";

      path = [
        pkgs.gitMinimal
      ];

      # restartIfChanged = false;
      # unitConfig.X-StopOnRemoval = false;

      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";
      };
    };

    systemd.user.timers.${serviceName} = {
      wantedBy = ["timers.target"];

      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "5m";
        Unit = "${serviceName}.service";
      };
    };
  };
}
