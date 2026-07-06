{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.ag = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules."host-ag"];
  };

  flake.nixosModules."host-ag" = {...}: {
    imports = with self.nixosModules; [
      base
      disks-normal
    ];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    networking.hostName = "ag";

    system.stateVersion = "26.05";
  };
}
