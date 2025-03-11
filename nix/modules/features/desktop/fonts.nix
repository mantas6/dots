{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (lib.elem "desktop" config.features) {
    fonts.packages = with pkgs; [
      nerd-fonts.anonymice
      ubuntu_font_family
      noto-fonts-emoji
    ];
  };
}
