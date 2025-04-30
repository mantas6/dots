# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{...}: {
  imports = [
    ./hardware.nix
    ../../modules
  ];

  disko.devices.disk.main-disk.device = "/dev/nvme0n1";

  features.list = [
    "amd"
    "desktop"
    "develop"
    # "disks/normal"
  ];

  networking.interfaces = {
    eth0.wakeOnLan.enable = true;
  };

  systemd.network.links."10-eth99" = {
    matchConfig.PermanentMACAddress = "f8:01:b4:58:14:9f";
    linkConfig.Name = "eth99";
  };

  # features.docker-compose = ["test" "test2"];
  features.docker-compose = [];

  # services.xserver.dpi = 100;

  # https://nixos.wiki/wiki/Power_Management
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
  '';

  networking.hostName = "ix";

  system.stateVersion = "24.05";
}
