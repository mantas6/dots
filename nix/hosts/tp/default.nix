{...}: {
  disko.devices.disk.main-disk.device = "/dev/nvme0n1";

  features.sets = [
    "disks.encrypted"
    "hardware.amd"
    "collections.desktop"
    "collections.develop"
    "progs.shell"
    "services.docker"
    "hardware.backlight"
  ];

  networking.stevenblack.enable = true;
  networking.networkmanager.enable = true;
  users.users.mantas.extraGroups = ["networkmanager"];

  services.logind.settings.Login.HandlePowerKey = "suspend";

  networking.hostName = "tp";

  system.stateVersion = "25.05";
}
