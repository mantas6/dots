{...}: {
  flake.nixosModules."collections-desktop" = {pkgs, ...}: {
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
          version = "6.6";
          src = pkgs.fetchgit {
            url = "https://git.suckless.org/dwm";
            rev = "693d94d350c806e77677c35958e18590c26e19d2"; # tag: 6.6
            hash = "sha256-fD97OpObSOBTAMc3teejS0u2h4hCkMVYJrNZ6F4IaFs=";
          };
        });
    };
  };
}
