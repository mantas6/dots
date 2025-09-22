# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{...}: {
  imports = [
    ./hardware.nix
    ../../modules
  ];

  disko.devices.disk.main-disk.device = "/dev/sda";

  features.sets = [
    "disks.normal"
    "jobs.updates"
    "router"
    # "docker"
  ];

  users.users.mantas.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIOLvKAVZSLkt8QQ8W0ZgDs4yzwB6rFQpO0F9W68FPL6 mantas@w"
  ];


  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=ttyS1,115200n8"
    "console=ttyS2,115200n8"
    "console=ttyS3,115200n8"
  ];
  boot.loader.grub.extraConfig = "
   serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
   terminal_input serial
   terminal_output serial
    ";

  networking.hostName = "rt";

  system.stateVersion = "25.05";
}
