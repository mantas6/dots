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

  hardware.bluetooth.enable = true;

  # rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true; # if not already enabled
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  environment.systemPackages = with pkgs; [
    xorg.xinit
    xclip
    arandr
    autorandr
    picom
    dex
    redshift
    unclutter
    numlockx

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
    gnome-themes-extra
    pavucontrol

    alacritty
    chromium
    firefox
    feh
  ];
}
