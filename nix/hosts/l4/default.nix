# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{pkgs, ...}: {
  imports = [
    ./hardware.nix
    ../../modules
  ];

  disko.devices.disk.main-disk.device = "/dev/sda";

  features.list = [
    "disks/normal"
    "backlight"
  ];

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

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

  systemd.user.services.sat-backups = {
    script = "/home/mantas/Offload/Sat/run";

    path = with pkgs; [
      openssl
      bash
      jq
    ];

    serviceConfig = {
      Type = "oneshot";
      After = "network-online.target";
      Wants = "network-online.target";
    };
  };

  systemd.user.timers.sat-backups = {
    wantedBy = ["timers.target"];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      AccuracySec = "6h";
      RandomizedDelaySec = "1h";
      Unit = "sat-backups.service";
    };
  };

  services.logind.powerKey = "poweroff";

  console.font = "ter-732n";

  networking.hostName = "l4";

  system.stateVersion = "25.05";
}
