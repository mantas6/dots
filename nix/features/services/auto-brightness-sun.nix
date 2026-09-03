{...}: {
  flake.modules.nixos."services-auto-brightness-sun" = {pkgs, ...}: let
    dayBrightness = "25%";
    nightBrightness = "5%";
    coordinates = "54.0N 23.0E";

    sunBrightness = pkgs.writeShellApplication {
      name = "sun-brightness";
      runtimeInputs = [pkgs.sunwait pkgs.brightnessctl];
      text =
        /*
        bash
        */
        ''
          status=0
          sunwait poll civil ${coordinates} || status=$?
          case $status in
            2) brightnessctl set ${dayBrightness} ;;
            3) brightnessctl set ${nightBrightness} ;;
            *) printf 'sunwait failed with status %d\n' "$status" >&2; exit "$status" ;;
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
