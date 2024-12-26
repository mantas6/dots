{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./tldr.nix
  ];

  options = {
    develop.enable = lib.mkEnableOption "enables development progs";
  };

  config = lib.mkIf config.develop.enable {
    environment.systemPackages = with pkgs; [
      neovim
      tmux
      sesh

      php83
      php83Packages.composer
      nodejs_22
      go
      gcc
      lua51Packages.lua
      lua51Packages.luarocks
      lua-language-server
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
