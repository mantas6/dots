{pkgs, ...}: {
  imports = [
    ./xserver.nix
    ./fonts.nix
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


  # programs.gnupg.agent.enable = true;

  environment.systemPackages = with pkgs; [
    xorg.xinit
    xclip
    arandr
    autorandr
    picom
    dex
    redshift

    (
      rofi.override {
        plugins = [
          rofi-emoji
          rofi-pass
        ];
      }
    )

    pass

    lxappearance

    alacritty
    chromium
    firefox
    feh
  ];
}
