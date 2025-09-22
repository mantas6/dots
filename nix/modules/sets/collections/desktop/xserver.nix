{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (lib.elem "collections.desktop" config.features.sets) {
    services = {
      xserver = {
        enable = true;

        windowManager.awesome.enable = true;

        displayManager.startx.enable = true;

        autoRepeatDelay = 250;
        autoRepeatInterval = 15;

        xkb = {
          layout = "us,lt";
          # options = "ctrl:swapcaps";
        };
      };

      libinput.mouse = {
        naturalScrolling = true;
        accelSpeed = "-1";
      };
    };
  };
}
