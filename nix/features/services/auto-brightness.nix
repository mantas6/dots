{...}: {
  flake.modules.nixos."services-auto-brightness" = {pkgs, ...}: let
    dayBrightness = "25%";
    nightBrightness = "1%";
    coordinates = "54.0N 23.0E";

    sunBrightness = pkgs.writeShellApplication {
      name = "sun-brightness";
      runtimeInputs = [pkgs.sunwait pkgs.brightnessctl];
      text =
        /*
        bash
        */
        ''
          rc=0
          sunwait poll civil ${coordinates} || rc=$?
          case $rc in
            2) brightnessctl set ${dayBrightness} ;;
            3) brightnessctl set ${nightBrightness} ;;
          esac
        '';
    };
  in {
    systemd.services.sun-brightness = {
      description = "Adjust screen brightness by sun position";
      serviceConfig = {
        Type = "oneshot";
        User = "mantas";
        ExecStart = "${sunBrightness}/bin/sun-brightness";
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
