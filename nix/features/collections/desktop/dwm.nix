{...}: {
  flake.nixosModules."collections-desktop" = {pkgs, ...}: {
    # dwm built from the official suckless release with official patches applied,
    # plus our own config.h on top. Awesome stays enabled (see xserver.nix) so it
    # remains available as a fallback during the migration.
    services.xserver.windowManager.dwm = {
      enable = true;
      package =
        (pkgs.dwm.override {
          # config.h is copied over config.def.h by the nixpkgs dwm builder.
          conf = ./dwm/config.h;

          # required by the alpha patch (bar transparency, links -lXrender)
          extraLibs = [pkgs.libxrender];

          # Official suckless patches. Order matters: alwaysontop introduces the
          # `iscentered` client field, so it must precede center.
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
          # Pin the dwm source to the immutable 6.6 release commit so nixpkgs
          # bumps can't change the source out from under our patches and break
          # the build. (git is used instead of the tarball because suckless
          # re-rolls release tarballs, changing their hash.)
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
