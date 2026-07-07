{...}: {
  flake.nixosModules."collections-desktop" = {pkgs, ...}: {
    # dwm built from the official suckless release with official patches applied,
    # plus our own config.h on top. Awesome stays enabled (see xserver.nix) so it
    # remains available as a fallback during the migration.
    services.xserver.windowManager.dwm = {
      enable = true;
      package = pkgs.dwm.override {
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
      };
    };
  };
}
