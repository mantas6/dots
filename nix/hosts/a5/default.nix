{...}: {
  disko.devices.disk.main-disk.device = "/dev/nvme0n1";

  features.sets = [
    "disks.normal"
    # "hardware.nvidia"
    # "hardware.amd"
    "collections.desktop"
    "collections.develop"
    "progs.shell"
    "services.printing"
    "services.docker"
    "quirks.amd-sleep"
  ];

  features.wakeOnLanAdapterMAC = "10:ff:e0:6d:48:60";

  boot.loader.grub.useOSProber = true;

  services.xserver.dpi = 100;

  networking.hostName = "a5";

  system.stateVersion = "25.05";
}
