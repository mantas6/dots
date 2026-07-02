{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.mt = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules."host-mt"];
  };

  flake.nixosModules."host-mt" = {...}: {
    imports = with self.nixosModules; [
      base
      disks-normal
      jobs-updates
      hardware-backlight
      quirks-prevent-sleep
      purposes-monitor
    ];

    disko.devices.disk.main-disk.device = "/dev/sda";

    networking.hostName = "mt";

    system.stateVersion = "26.05";
  };
}
