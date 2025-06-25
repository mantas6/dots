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
    "disks/normal"
    "nvidia"
    "desktop"
    "develop"
    "quirks/amd-sleep"
  ];

  # services.xserver.dpi = 100;

  networking.hostName = "a5";

  system.stateVersion = "25.05";
}
