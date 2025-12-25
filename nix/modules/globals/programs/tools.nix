{pkgs-unstable, ...}: {
  environment.systemPackages = with pkgs-unstable; [
    vim
    wget
    curl
    git
    fastfetch
    lf
    yazi
    gh
    unzip
    htop
    btop
    file

    killall

    pciutils
    usbutils
    lm_sensors
  ];
}
