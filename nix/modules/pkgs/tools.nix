{pkgs-unstable, ...}: {
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
    fzf
    delta
    unzip
    sysz
    htop
    btop
    jq

    zsh-autosuggestions
    zsh-autocomplete
    zsh-syntax-highlighting
    zsh-fzf-tab

    pciutils
  ];

  programs.nh = {
    enable = true;
    flake = "/home/mantas/Repos/dotfiles";
  };
}
