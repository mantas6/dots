{...}: {
  flake.modules.nixos."collections-desktop" = {
    # System-wide dark preference; no desktop environment sets one under dwm
    environment.etc = {
      "xdg/gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=true
      '';
      "xdg/gtk-4.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=true
        gtk-interface-color-scheme=dark
      '';
    };

    # libadwaita and other GSettings readers
    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
          };
        }
      ];
    };

    # Sets QT_QPA_PLATFORMTHEME and installs qt5ct and qt6ct (handles both)
    qt = {
      enable = true;
      platformTheme = "qt5ct";
    };
  };
}
