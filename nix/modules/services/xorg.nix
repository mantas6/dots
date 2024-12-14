{pkgs, ...}: {
  services = {
    xserver = {
      enable = true;

      windowManager.awesome.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    xorg.xinit
    xclip

    lxappearance

    alacritty
    chromium
    firefox
    feh
  ];
}
