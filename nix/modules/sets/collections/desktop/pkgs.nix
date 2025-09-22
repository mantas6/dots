{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (lib.elem "desktop" config.features.sets) {
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
      wezterm

      zathura
      qrencode

      chromium
      qutebrowser
    ];

    services.udisks2.enable = true;

    programs.chromium = {
      enable = true;

      extensions = [
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      ];

      extraOpts = {
        "BrowserSignin" = 0;
        "SyncDisabled" = true;
        "PasswordManagerEnabled" = false;
      };
    };

    programs.firefox = {
      enable = true;
      policies = {};
      preferences = {};
    };
  };
}
