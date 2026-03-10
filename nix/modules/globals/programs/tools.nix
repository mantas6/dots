{pkgs-unstable, ...}: {
  environment.systemPackages = with pkgs-unstable; [
    vim
    wget
    curl
    unzip
    htop
    btop
    file

    killall
  ];
}
