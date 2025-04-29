# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{...}: {
  imports = [
    ./hardware.nix
    ../../modules
  ];

  disko.devices.disk.main-disk.device = "/dev/vda";

  features = [
    "desktop"
    "develop"
    "disks/normal"
  ];

  services.spice-vdagentd.enable = true;

  networking.hostName = "utm";

  system.stateVersion = "24.11";
}
