{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (lib.elem "desktop" config.features) {
    services = {
      xserver = {
        enable = true;

        windowManager.awesome.enable = true;

        displayManager.startx.enable = true;

        xkb = {
          layout = "us,lt";
          options = "ctrl:swapcaps";
        };
      };

      libinput.mouse = {
        naturalScrolling = true;
        accelSpeed = "-1";
      };
    };
  };
}
