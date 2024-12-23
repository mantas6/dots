{
  services = {
    xserver = {
      enable = true;

      windowManager.awesome.enable = true;

      displayManager.startx.enable = true;

      xkb.layout = "us,lt";
    };

    libinput.mouse = {
      naturalScrolling = true;
      accelSpeed = "-1";
    };
  };
}
