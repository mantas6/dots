{...}: {
  flake.modules.nixos."collections-desktop" = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      xinit
      xsetroot
      xclip
      arandr
      autorandr
      picom
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
