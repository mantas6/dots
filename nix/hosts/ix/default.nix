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
    "services.printing"
    "services.docker"
    "quirks.amd-sleep"
    # "disks.normal"
  ];

  features.wakeOnLanAdapterMAC = "04:7c:16:4f:88:ea";

  boot.loader.grub.useOSProber = true;

  services.logind.powerKey = "suspend";

  # systemd.network.links."10-unmn0" = {
  #   matchConfig.PermanentMACAddress = "60:7d:09:a9:4a:1c";
  #   linkConfig = {
  #     Name = "unmn0";
  #   };
  # };

  # networking.interfaces.unmn0.useDHCP = false;

  # features.docker-compose = ["test" "test2"];
  # features.services = ["photosync"];

  # services.xserver.dpi = 100;

  networking.hostName = "ix";

  system.stateVersion = "24.05";
}
