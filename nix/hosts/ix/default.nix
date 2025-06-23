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
    "printing"
    "quirks/amd-sleep"
    # "disks/normal"
  ];

  # networking.interfaces = {
  #   net0.wakeOnLan.enable = true;
  # };

  systemd.network.links."10-net0" = {
    matchConfig.PermanentMACAddress = "04:7c:16:4f:88:ea";
    linkConfig = {
      Name = "net0";
      WakeOnLan = "magic";
    };
  };

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
