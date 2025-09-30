{
  pkgs-unstable,
  lib,
  config,
  ...
}: {
  config = lib.mkIf (lib.elem "collections.develop" config.features.sets) {
    # lua_ls fix
    programs.nix-ld.enable = true;

    environment.variables.EDITOR = lib.mkDefault "${pkgs-unstable.neovim}/bin/vim";

    environment.systemPackages = with pkgs-unstable; [
      neovim
      tmux
      sesh
      direnv

      php84
      php84Packages.composer
      nodejs_22
      go
      gcc
      lua51Packages.lua
      lua51Packages.luarocks
      python3
      exiftool

      shellcheck
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
