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
    yq-go
    file

    killall

    pciutils
    usbutils
    lm_sensors
  ];
}
