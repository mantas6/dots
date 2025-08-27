# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{...}: {
  imports = [
    ./hardware.nix
    ../../modules
  ];

  disko.devices.disk.main-disk.device = "/dev/sda";

  features.list = [
    "disks/normal"
    "jobs/updates"
    # "router"
    "docker"
  ];

  users.users.mantas.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCXxAEug9dQiyzstH7QUgE7/moT6fQrtXKcQBM0BKpWo05rRwArX/0GLZfy1GJn1/Kvj1YxX9+//hSZURkqLhi4Q4DWvHPDo2EH6T40Ql3P9lgt7GLTCqS60Asgml1akn4r+BSvb0uHsoAwB8zGE2QssJuxNZjl0jCNVJzTPSxUVLuv9l+hvjgFSRsSAdrC3q4VEZ1NHE6hbpS0B8Jpsu9x1zFmieLtjYBRWaycXxuGKd9T3EpKxo5nufvU187uqpcKGXS0KUtzqxgmrQVL/luGeiHrZq+nbiRXGT2F6GgIbdvrPfzxePyF3Noh1GevdL1iXJjF262kMxDM5CKu3Kj8d0D8ZqxwAfMFMgzKH6JZOyMOFmJBh28uJ+OgXKaPwMLbnx/pl6fKDRjXyjGkzaTU/6KUrH0rkovKk67IZfGssQfsJGhi3/l+dkB2aP2X0vivsB4lAo/VBaLA/UbhcakT/yuhyhp+vkfFTpns6S9gUrEYf/vDcVZwU0AIhNZc1Ek= mantas@w"
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
