{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./tldr.nix
  ];

  config = lib.mkIf (lib.elem "develop" config.features) {
    # lua_ls fix
    programs.nix-ld.enable = true;

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
