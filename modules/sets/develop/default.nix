{
  pkgs,
  lib,
  config,
  ...
}: let
  opts = config.develop;
in {
  imports = [
    ./tldr.nix
  ];

  options = {
    develop.enable = lib.mkEnableOption "enables development progs";
  };

  config = lib.mkIf opts.enable {
    environment.systemPackages = with pkgs; [
      php83
      php83Packages.composer
      nodejs_22
      go
      gcc
      lua51Packages.lua
      lua51Packages.luarocks
      python3
      shellcheck
      ripgrep
      fd

      lazygit
      lazydocker

      nixd
      alejandra
    ];
  };
}
