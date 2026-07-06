{...}: {
  flake.nixosModules."collections-desktop" = {
    config,
    pkgs,
    ...
  }: let
    awesomePkg = config.services.xserver.windowManager.awesome.package;

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

        [ -x "$(command -v auto-suspend)" ] && auto-suspend &

        ${pkgs.feh}/bin/feh --bg-fill --no-fehbg "$XDG_STATE_HOME/wallpaper/current.jpg" &

        exec ${awesomePkg}/bin/awesome
      '';
  in {
    environment.variables.XINITRC = "${xinitrc}";
  };
}
