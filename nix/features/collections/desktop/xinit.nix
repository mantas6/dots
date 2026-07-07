{...}: {
  flake.nixosModules."collections-desktop" = {
    config,
    pkgs,
    ...
  }: let
    dwmPkg = config.services.xserver.windowManager.dwm.package;

    xinitrc =
      pkgs.writeScript "xinitrc"
      /*
      bash
      */
      ''
        #!${pkgs.runtimeShell}

        ${pkgs.xset}/bin/xset -b

        ${pkgs.unclutter}/bin/unclutter &
        ${pkgs.lxsession}/bin/lxpolkit &
        (sleep 3 && ${pkgs.redshift}/bin/redshift -O 4500) &

        [ -x "$(command -v auto-suspend)" ] && auto-suspend &

        ${pkgs.feh}/bin/feh --bg-fill --no-fehbg "$XDG_STATE_HOME/wallpaper/current.jpg" &

        while :; do
          ${pkgs.xsetroot}/bin/xsetroot -name "$(bar -p 2 2>/dev/null)"
          sleep 2
        done &

        exec ${dwmPkg}/bin/dwm
        # exec ${config.services.xserver.windowManager.awesome.package}/bin/awesome
      '';
  in {
    environment.variables.XINITRC = "${xinitrc}";
  };
}
