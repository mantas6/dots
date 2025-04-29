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
    usbutils
  ];

  programs.nh = {
    enable = true;
    flake = "/home/mantas/.dots";
  };
}
