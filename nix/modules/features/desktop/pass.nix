{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (lib.elem "desktop" config.features) {
    programs.gnupg = {
      agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-gtk2;
      };
    };

    environment.systemPackages = with pkgs; [
      pass
      rofi-pass
    ];
  };
}
