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
    "hardware.amd"
    "collections.desktop"
    "collections.develop"
    # "services.printing"
    "services.docker"
    "quirks.amd-sleep"
    # "purposes.sat"
    # "disks.normal"
  ];

  # try pkgs.linuxPackages_6_10 to prevent sleep issues
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # https://www.reddit.com/r/Fedora/comments/1gj29ub/is_anyone_having_this_suspendwake_up_problem_as/

  features.wakeOnLanAdapterMAC = "04:7c:16:4f:88:ea";

  boot.loader.grub.useOSProber = true;

  services.logind.powerKey = "suspend";

  # services.xserver.dpi = 100;

  networking.hostName = "ix";

  system.stateVersion = "24.05";
}
