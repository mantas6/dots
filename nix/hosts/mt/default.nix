{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.mt = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-mt"];
  };

  flake.modules.nixos."host-mt" = {...}: {
    imports = with self.modules.nixos; [
      base
      base-home
      disks-normal
      jobs-updates
      hardware-backlight
      services-auto-brightness
      quirks-prevent-sleep
      purposes-monitor
    ];

    disko.devices.disk.main-disk.device = "/dev/sda";

    networking.hostName = "mt";

    system.stateVersion = "26.05";
  };
}
