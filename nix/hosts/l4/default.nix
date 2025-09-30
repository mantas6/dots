# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{pkgs, ...}: {
  imports = [
    ./hardware.nix
    ../../modules
  ];

  disko.devices.disk.main-disk.device = "/dev/sda";

  features.sets = [
    "disks.normal"
    "jobs.updates"
    "hardware.backlight"
    "services.docker"
    "services.memos"
    # "services.photosync"
    "quirks.prevent-sleep"
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];

  environment.systemPackages = with pkgs; [
    exiftool
    python3Minimal
  ];

  services.caddy = {
    enable = true;
    virtualHosts = {
      "http://gal".extraConfig = ''
        reverse_proxy http://localhost:8079
      '';
      "http://memos".extraConfig = ''
        reverse_proxy http://localhost:5230
      '';
    };
  };

  systemd.user.services.sat-backups = {
    script = "/home/mantas/Offload/Sat/run";

    path = with pkgs; [
      openssl
      bash
      jq
      curl
    ];

    after = ["network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      Type = "oneshot";
    };

    startAt = "daily";
  };

  systemd.user.timers.sat-backups = {
    timerConfig = {
      Persistent = true;
      AccuracySec = "6h";
      RandomizedDelaySec = "1h";
    };
  };

  services.udisks2.enable = true;

  console.font = "ter-732n";

  networking.hostName = "l4";

  system.stateVersion = "25.05";
}
