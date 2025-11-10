{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (lib.elem "collections.desktop" config.features.sets) {
    fonts = {
      fontDir.enable = true;
      fontconfig.enable = true;

      packages = with pkgs; [
        nerd-fonts.anonymice
        # ubuntu_font_family
        ubuntu-classic
        noto-fonts-emoji
      ];
    };
  };
}
