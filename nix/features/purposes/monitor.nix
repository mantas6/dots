{...}: {
  flake.nixosModules."purposes-monitor" = {
    config,
    pkgs,
    ...
  }: let
    awesomePkg = config.services.xserver.windowManager.awesome.package;

    xinitrc =
      pkgs.writeScript "monitor-xinitrc"
      /*
      bash
      */
      ''
        #!${pkgs.runtimeShell}

        ${pkgs.xset}/bin/xset s off -dpms
        ${pkgs.xset}/bin/xset s noblank
        ${pkgs.brightnessctl}/bin/brightnessctl set 25%

        base_url=$(cat "${config.age.secrets.sat-base-url.path}")

        (${pkgs.coreutils}/bin/sleep 5 && ${pkgs.chromium}/bin/chromium --kiosk --noerrdialogs --disable-infobars --no-first-run "$base_url/api/probes/display/home") &

        exec ${awesomePkg}/bin/awesome
      '';
  in {
    services = {
      xserver = {
        enable = true;

        windowManager.awesome.enable = true;
        displayManager.startx.enable = true;

        serverFlagsSection = ''
          Option "AutoAddDevices" "false"
        '';
      };

      getty.autologinUser = "mantas";
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
