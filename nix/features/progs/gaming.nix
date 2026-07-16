{...}: {
  flake.modules.nixos."progs-gaming" = {
    lib,
    config,
    pkgs,
    ...
  }: {
    programs.steam = {
      enable = true;
    };

    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "steam"
        "steam-unwrapped"
      ];
  };
}
