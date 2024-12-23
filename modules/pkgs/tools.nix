{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    neovim
    wget
    curl
    git
    fastfetch
    lf
    yazi
    bat
    tmux
    sesh
    stow
    zoxide
    starship
    eza
    trash-cli
    gh
    gum
    fzf
    delta
    unzip
    sysz
    htop
    btop
    htop
    tealdeer

    pciutils
  ];
}
