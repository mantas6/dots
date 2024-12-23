{pkgs, ...}: {
  imports = [
    ./tldr.nix
  ];

  environment.systemPackages = with pkgs; [
    php83
    php83Packages.composer
    nodejs_22
    go
    gcc
    lua
    luajitPackages.luarocks
    python3
    shellcheck
    ripgrep
    fd

    lazygit
    lazydocker

    nixd
    alejandra
  ];
}
