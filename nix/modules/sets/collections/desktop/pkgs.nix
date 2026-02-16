{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (lib.elem "collections.desktop" config.features.sets) {
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

      gimp

      lxappearance
      gnome-themes-extra
      feh

      alacritty
      wezterm

      zathura
      qrencode
    ];
  };
}
