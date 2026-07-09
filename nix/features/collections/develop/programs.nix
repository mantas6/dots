{...}: {
  flake.nixosModules."collections-develop" = {
    pkgs-unstable,
    lib,
    inputs,
    ...
  }: let
    pkgs-unstable-unfree = import inputs.nixpkgs-unstable {
      system = pkgs-unstable.stdenv.hostPlatform.system;
      config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          # "intelephense"
          "claude-code"
        ];
    };

    agenix = inputs.agenix.packages.${pkgs-unstable.stdenv.hostPlatform.system}.default;

    phpConfigured = pkgs-unstable.php85.buildEnv {
      extensions = {
        enabled,
        all,
      }:
        enabled
        ++ (with all; [
          pdo
          pdo_mysql
          pdo_sqlite
          mbstring
          bcmath
          curl
          zip
          intl
        ]);

      extraConfig = "memory_limit = 2G";
    };
  in {
    # lua_ls fix
    programs.nix-ld.enable = true;

    environment.variables.EDITOR = lib.mkDefault "${pkgs-unstable.neovim}/bin/vim";

    services.redis.servers.develop = {
      enable = true;
      port = 6379;
    };

    environment.systemPackages = with pkgs-unstable; [
      neovim
      tmux
      direnv

      phpConfigured
      phpConfigured.packages.composer
      sqlite

      nodejs_24
      go
      gcc
      lua51Packages.lua
      lua51Packages.luarocks

      # Art
      python313
      python313Packages.pip
      uv
      imagemagick
      exiftool
      ffmpeg

      shellcheck
      shfmt
      prettier
      stylua
      taplo
      tree-sitter

      pandoc
      ripgrep
      fd
      entr

      lazygit
      # diffnav
      lazydocker
      xh
      pastel
      onefetch

      opencode
      pkgs-unstable-unfree.claude-code

      gnumake
      gitleaks
      openssl
      parallel
      speedtest-cli

      # LSP servers
      nixd
      gopls
      pyright
      lua-language-server
      # pkgs-unstable-unfree.intelephense
      phpactor
      bash-language-server
      typescript-language-server
      dockerfile-language-server
      vscode-langservers-extracted
      # clang-tools

      alejandra
      # deadnix

      agenix
    ];
  };
}
