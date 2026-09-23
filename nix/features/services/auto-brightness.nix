{...}: {
  flake.modules.nixos."services-auto-brightness" = {pkgs, ...}: let
    dayBrightness = "25%";
    nightBrightness = "5%";
    nightStart = 23;
    nightEnd = 7;

    timeBrightness = pkgs.writeShellApplication {
      name = "time-brightness";
      runtimeInputs = [pkgs.coreutils pkgs.brightnessctl];
      text =
        /*
        bash
        */
        ''
          hour=$(date +%-H)
          if [[ $hour -ge ${toString nightStart} || $hour -lt ${toString nightEnd} ]]; then
            brightnessctl set ${nightBrightness}
          else
            brightnessctl set ${dayBrightness}
          fi
        '';
    };
  in {
    systemd.services.time-brightness = {
      description = "Adjust screen brightness by time of day";
      serviceConfig = {
        Type = "oneshot";
        User = "mantas";
        ExecStart = "${timeBrightness}/bin/time-brightness";
      };
    };

    systemd.timers.time-brightness = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "15min";
        Persistent = true;
      };
    };
  };
}
