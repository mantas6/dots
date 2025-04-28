{
  pkgs-unstable,
  ...
}: {
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
    file

    killall

    pciutils
  ];

  programs.nh = {
    enable = true;
    flake = "/home/mantas/.dots";
  };
}
