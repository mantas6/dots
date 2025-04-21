{
  pkgs-unstable,
  lib,
  ...
}: let
  # TODO: make argument as an array
  sharePkg = pkg: {
    "share/${lib.getName pkg.name}".source = "${pkg}";
  };
in {
  environment.systemPackages = with pkgs-unstable; [
    vim
    wget
    curl
    git
    fastfetch
    lf
    yazi
    bat
    stow
    zoxide
    starship
    eza
    trash-cli
    gh
    gum
    glow
    fzf
    delta
    unzip
    sysz
    htop
    btop
    jq

    pciutils
  ];

  environment.etc =
    sharePkg pkgs-unstable.zsh-autosuggestions
    // sharePkg pkgs-unstable.zsh-syntax-highlighting
    // sharePkg pkgs-unstable.zsh-fzf-tab
    // sharePkg pkgs-unstable.zsh-completions;

  programs.nh = {
    enable = true;
    flake = "/home/mantas/Repos/dotfiles";
  };
}
