{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
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
    fzf
    delta
    unzip
    sysz
    htop
    btop
    htop

    pciutils
  ];
}
