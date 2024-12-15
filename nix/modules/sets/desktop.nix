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

  environment.systemPackages = with pkgs; [
    xorg.xinit
    xclip
    arandr
    autorandr
    picom

    rofi
    rofi-emoji
    rofi-pass

    pass

    lxappearance

    noto-fonts-emoji

    alacritty
    chromium
    firefox
    feh
  ];
}
