# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{pkgs, ...}: {
  imports = [
    ./hardware.nix
    ../../modules
  ];

  disko.devices.disk.main-disk.device = "/dev/nvme0n1";

  features.sets = [
    "disks.normal"
    "jobs.updates"
    "purposes.router"
  ];

  features.useZshShell = false;

  environment.systemPackages = with pkgs; [
    cmatrix
  ];

  networking.hostName = "pd";

  system.stateVersion = "25.05";
}
