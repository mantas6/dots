{
  lib,
  config,
  pkgs-unstable,
  ...
}: {
  config = lib.mkIf (lib.elem "desktop" config.features.list) {
    fonts = {
      fontDir.enable = true;
      fontconfig.enable = true;

      packages = with pkgs-unstable; [
        nerd-fonts.anonymice
        ubuntu_font_family
        noto-fonts-emoji
      ];
    };
  };
}
