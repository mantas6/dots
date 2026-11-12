{...}: {
  flake.modules.nixos.base = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      wget
      curl
      unzip
      htop
      file
      killall
    ];
  };
}
