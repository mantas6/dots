{...}: {
  flake.modules.nixos."collections-desktop" = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      xclip
      arandr
      autorandr
      dex
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
