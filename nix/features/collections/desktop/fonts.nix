{...}: {
  flake.nixosModules."collections-desktop" = {pkgs, ...}: {
    fonts = {
      fontDir.enable = true;
      fontconfig.enable = true;

      packages = with pkgs; [
        nerd-fonts.anonymice
        # ubuntu_font_family
        ubuntu-classic
        noto-fonts-color-emoji
      ];
    };
  };
}
