{...}: {
  flake.modules.nixos.base = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      vim
      wget
      curl
      unzip
      htop
      file
      killall
    ];
  };
}
