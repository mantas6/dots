{pkgs, ...}: {
  services = {
    xserver = {
      enable = true;

      windowManager.awesome.enable = true;

      displayManager.startx.enable = true;
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.anonymice
    ubuntu_font_family
  ];

  # location.provider = "manual";
  # location.latitude = 54.0;
  # location.longitude = 25.0;
  #
  # services.redshift = {
  #   enable = true;
  #   temperature = {
  #     day = 4500;
  #     night = 4500;
  #   };
  # };

  services.libinput.mouse = {
    naturalScrolling = true;
    accelSpeed = "-1";
  };

  environment.systemPackages = with pkgs; [
    xorg.xinit
    xclip
    arandr
    autorandr
    picom
    dex
    redshift

    # (
    #   rofi.override (old: {
    #     plugins = old.plugins ++ [
    #       rofi-emoji
    #       rofi-pass
    #     ];
    #   })
    # )

    pass

    lxappearance

    noto-fonts-emoji

    alacritty
    chromium
    firefox
    feh
  ];
}
