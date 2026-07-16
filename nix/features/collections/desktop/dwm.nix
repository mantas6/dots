{...}: {
  flake.modules.nixos."collections-desktop" = {pkgs, ...}: {
    services.xserver.windowManager.dwm = {
      enable = true;
      package =
        (pkgs.dwm.override {
          conf = ./dwm/config.h;

          extraLibs = [pkgs.libxrender];

          patches = [
            ./dwm/patches/alpha.diff
            ./dwm/patches/pertag.diff
            ./dwm/patches/hide_vacant_tags.diff
            ./dwm/patches/fsignal.diff
            ./dwm/patches/movestack.diff
            ./dwm/patches/alwaysontop.diff
            ./dwm/patches/warp.diff
            ./dwm/patches/cyclelayouts.diff
            ./dwm/patches/center.diff
            ./dwm/patches/restartsig.diff
            ./dwm/patches/title-nocolor.diff
          ];
        })
        .overrideAttrs (_: {
          version = "6.8";
          src = pkgs.fetchgit {
            url = "https://git.suckless.org/dwm";
            rev = "f63cde9354504ee9cfecc07517c03736d0f90c26"; # tag: 6.8
            hash = "sha256-mkMFmqV9NVGTdDGqW8f+T7r0YQNU1KDsn6uRcacoNco=";
          };
        });
    };
  };
}
