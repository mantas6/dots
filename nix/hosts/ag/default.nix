{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.ag = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-ag"];
  };

  flake.modules.nixos."host-ag" = {...}: {
    imports = with self.modules.nixos; [
      base
      base-home
      disks-normal
      jobs-updates
      services-docker
      purposes-app-server
    ];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    features.swapSizeInGB = 2;

    networking.hostName = "ag";

    system.stateVersion = "26.05";
  };
}
