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
    "docker"
  ];

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

  users.users.mantas.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCXxAEug9dQiyzstH7QUgE7/moT6fQrtXKcQBM0BKpWo05rRwArX/0GLZfy1GJn1/Kvj1YxX9+//hSZURkqLhi4Q4DWvHPDo2EH6T40Ql3P9lgt7GLTCqS60Asgml1akn4r+BSvb0uHsoAwB8zGE2QssJuxNZjl0jCNVJzTPSxUVLuv9l+hvjgFSRsSAdrC3q4VEZ1NHE6hbpS0B8Jpsu9x1zFmieLtjYBRWaycXxuGKd9T3EpKxo5nufvU187uqpcKGXS0KUtzqxgmrQVL/luGeiHrZq+nbiRXGT2F6GgIbdvrPfzxePyF3Noh1GevdL1iXJjF262kMxDM5CKu3Kj8d0D8ZqxwAfMFMgzKH6JZOyMOFmJBh28uJ+OgXKaPwMLbnx/pl6fKDRjXyjGkzaTU/6KUrH0rkovKk67IZfGssQfsJGhi3/l+dkB2aP2X0vivsB4lAo/VBaLA/UbhcakT/yuhyhp+vkfFTpns6S9gUrEYf/vDcVZwU0AIhNZc1Ek= mantas@w"
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

  systemd.user.services.sat-backups = {
    script = "/home/mantas/Offload/Sat/run";

    path = with pkgs; [
      openssl
      bash
      jq
      curl
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

  services.udisks2.enable = true;

  console.font = "ter-732n";

  networking.hostName = "l4";

  system.stateVersion = "25.05";
}
