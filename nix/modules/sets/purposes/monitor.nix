{
  lib,
  config,
  pkgs,
  ...
}: let
  name = "purposes.monitor";

  awesomePkg = config.services.xserver.windowManager.awesome.package;

  xinitrc =
    pkgs.writeScript "monitor-xinitrc"
    /*
    bash
    */
    ''
      #!${pkgs.runtimeShell}
      exec ${awesomePkg}/bin/awesome
    '';
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      services = {
        xserver = {
          enable = true;

          windowManager.awesome.enable = true;
          displayManager.startx.enable = true;
        };

        getty.autologinUser = "mantas";
      };

      # After autologin on tty1, start X (awesome) automatically.
      environment.loginShellInit =
        /*
        bash
        */
        ''
          if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
            exec startx ${xinitrc}
          fi
        '';
    })
  ];
}
