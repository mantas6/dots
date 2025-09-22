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
      script = "${pkgs.gitMinimal}/bin/git pull";

      path = with pkgs; [
        gitMinimal
      ];

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";
        WorkingDirectory = "%h/.local/share/password-store";
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
