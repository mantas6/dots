{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (lib.elem "collections.desktop" config.features.sets) {
    programs.gnupg = {
      agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-gtk2;
      };
    };

    environment.systemPackages = with pkgs; [
      pass
      rofi-pass
      pwgen
    ];
  };
}
