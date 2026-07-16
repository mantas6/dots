{...}: {
  flake.modules.nixos."services-auto-brightness" = {pkgs, ...}: let
    dayBrightness = "25%";
    nightBrightness = "1%";
    coordinates = "54.0N 23.0E";

    sunBrightness =
      pkgs.writeShellScript "sun-brightness"
      /*
      bash
      */
      ''
        #!${pkgs.runtimeShell}
        ${pkgs.sunwait}/bin/sunwait poll civil ${coordinates}
        case $? in
          2) ${pkgs.brightnessctl}/bin/brightnessctl set ${dayBrightness} ;;
          3) ${pkgs.brightnessctl}/bin/brightnessctl set ${nightBrightness} ;;
        esac
      '';
  in {
    systemd.services.sun-brightness = {
      description = "Adjust screen brightness by sun position";
      serviceConfig = {
        Type = "oneshot";
        User = "mantas";
        ExecStart = "${sunBrightness}";
      };
    };

    systemd.timers.sun-brightness = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "15min";
        Persistent = true;
      };
    };
  };
}
