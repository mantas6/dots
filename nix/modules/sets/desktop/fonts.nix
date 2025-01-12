{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf config.desktop.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.anonymice
      ubuntu_font_family
      noto-fonts-emoji
    ];
  };
}
