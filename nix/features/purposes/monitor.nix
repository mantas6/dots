{...}: {
  flake.modules.nixos."purposes-monitor" = {
    config,
    pkgs,
    ...
  }: let
    dwmPkg = config.services.xserver.windowManager.dwm.package;

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

    xinitrc =
      pkgs.writeScript "monitor-xinitrc"
      /*
      bash
      */
      ''
        #!${pkgs.runtimeShell}

        ${pkgs.xset}/bin/xset s off -dpms
        ${pkgs.xset}/bin/xset s noblank
        ${sunBrightness}

        ${pkgs.unclutter}/bin/unclutter &

        base_url=$(cat "${config.age.secrets.sat-base-url.path}")

        (${pkgs.coreutils}/bin/sleep 5 && ${pkgs.chromium}/bin/chromium --kiosk --noerrdialogs --disable-infobars --no-first-run "$base_url/api/probes/display/home") &

        exec ${dwmPkg}/bin/dwm
      '';
  in {
    age.secrets.sat-base-url = {
      file = ./../../../lib/secrets/sat-base-url.age;
      owner = "mantas";
    };

    services = {
      xserver = {
        enable = true;

        windowManager.dwm.enable = true;
        displayManager.startx.enable = true;

        serverFlagsSection = ''
          Option "AutoAddDevices" "false"
        '';
      };

      getty.autologinUser = "mantas";
    };

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

    environment.loginShellInit =
      /*
      bash
      */
      ''
        if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
          exec startx ${xinitrc}
        fi
      '';
  };
}
