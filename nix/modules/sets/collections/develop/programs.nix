{
  pkgs-unstable,
  lib,
  config,
  ...
}: let
  phpConfigured = pkgs-unstable.php84.buildEnv {
    extraConfig = "memory_limit = 2G";
  };
in {
  config = lib.mkIf (lib.elem "collections.develop" config.features.sets) {
    # lua_ls fix
    programs.nix-ld.enable = true;

    environment.variables.EDITOR = lib.mkDefault "${pkgs-unstable.neovim}/bin/vim";

    environment.systemPackages = with pkgs-unstable; [
      neovim
      tmux
      sesh
      direnv

      phpConfigured
      phpConfigured.packages.composer
      sqlite

      nodejs_24
      go
      gcc
      lua51Packages.lua
      lua51Packages.luarocks
      python3
      exiftool

      shellcheck
      shfmt
      prettier
      ripgrep
      fd
      entr

      lazygit
      lazydocker
      xh
      pastel

      gnumake
      gitleaks
      openssl
      parallel
      speedtest-cli

      nixd
      alejandra
      # deadnix
    ];
  };
}
