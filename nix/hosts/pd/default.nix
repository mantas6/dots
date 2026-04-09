# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{...}: {
  imports = [
    ./hardware.nix
    ../../modules
  ];

  disko.devices.disk.main-disk.device = "/dev/nvme0n1";

  features.sets = [
    "disks.normal"
    "jobs.updates"
    "purposes.router"
    "services.sat-backups"
  ];

  users.users.mantas.hashedPassword = "$y$j9T$9fIB3RWe.fVkunAycN6jD.$tsgfckKykjuNpmAfvcp5PqmyJdOaJG4NTpg54ESi5p3";

  features.swapSizeInGB = 2;
  # powerManagement.powertop.enable = true;

  system.autoUpgrade.dates = "01:00";

  networking.hostName = "pd";

  system.stateVersion = "25.05";
}
