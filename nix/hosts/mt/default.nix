{...}: {
  disko.devices.disk.main-disk.device = "/dev/sda";

  features.sets = [
    "disks.normal"
    "hardware.backlight"
    "quirks.prevent-sleep"
  ];

  networking.hostName = "mt";

  system.stateVersion = "26.05";
}
