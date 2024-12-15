{pkgs, ...}: {
  services = {
    xserver = {
      enable = true;

      windowManager.awesome.enable = true;

      displayManager.startx.enable = true;
    };
  };

  fonts.packages = [
    pkgs.nerd-fonts.anonymice
  ];

  environment.systemPackages = with pkgs; [
    xorg.xinit
    xclip
    arandr
    autorandr
    picom

    rofi
    rofi-emoji

    pass

    lxappearance

    noto-fonts-emoji

    alacritty
    chromium
    firefox
    feh
  ];
}
