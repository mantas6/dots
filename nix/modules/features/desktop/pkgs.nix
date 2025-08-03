{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (lib.elem "desktop" config.features.list) {
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
      xssstate
      maim

      (
        rofi.override {
          plugins = [rofi-emoji];
        }
      )

      lxappearance
      gnome-themes-extra
      feh

      alacritty
      chromium
      firefox

      zathura
      qrencode
    ];

    services.udisks2.enable = true;
  };
}
