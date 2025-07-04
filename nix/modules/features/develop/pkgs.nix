{
  pkgs-unstable,
  lib,
  config,
  ...
}: {
  config = lib.mkIf (lib.elem "develop" config.features.list) {
    # lua_ls fix
    programs.nix-ld.enable = true;

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

      nixd
      alejandra
      # deadnix
    ];
  };
}
