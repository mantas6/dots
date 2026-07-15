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
      base-home
      disks-normal
      jobs-updates
      services-docker
      # purposes-app-server
    ];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    networking.hostName = "ag";

    system.stateVersion = "26.05";
  };
}
